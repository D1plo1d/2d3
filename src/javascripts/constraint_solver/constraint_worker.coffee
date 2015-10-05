# A Worker for geometric constraint solving!!

# This code is being written with the idea of
# porting it to super-optimized ASM.js code
# in mind.
#
# For the entire CAD program, the efficiency of this
# code is the single biggest speed concern.
#
# So, conceptual elegance and abstraction is being traded
# for super-optimized code.


# Helpers for making arrays!
createFloat64Array = (size) -> new Float64Array(new ArrayBuffer(8*size))
createIDsArray = (size) -> new Uint16Array(new ArrayBuffer(2*size))

# The number of points we initialState ke room for
nPointsTotal = 128
# The number of points we presently have (starts 0 because we have none)
nPoints      = 0

# We store the state of points in an array of floating point numbers
# Like so:
#
#   [p0.x, p0.y, p1.x, p1.y, p2.x, p2.y ... ]
#
# Thus, storing n variables requires 2*n spaces
# And the index of the x and y components of point n are 2*n and 2*n+1.

# We store 3 different states:

# What the outside world believes the state of variables are

initialState = createFloat64Array(2 * nPointsTotal)

# The constraint solvers last step state

currentState = createFloat64Array(2 * nPointsTotal)

# Working space

currentStateMod = createFloat64Array(2 * nPointsTotal)



# If we ever need more points than nPointsTotal...
supportMorePoints = () ->
  nPointsTotal *= 2
  currentState = createFloat64Array(2 * nPointsTotal)
  currentStateMod = createFloat64Array(2 * nPointsTotal)
  initialState = createFloat64Array(2 * nPointsTotal)



# For tracking external references to points.
# For example, to find the x component of
# a point of a certain id:
#
#   currentState[2*pointIDs.indexOf(id)]
#
# You can get y by adding 1

pointIDs      = []

# The same idea with constraints!

constraintIDs = []

# We'll discuss constraints more shortly,
# but the general idea is that they give
# us a number describing how much a constraint is not
# satisified. So bigger means less satisfied,
# and perfectly satisified is 0. (This is sometimes called
# the cost function of the constraint, C.)
#
# Depending on this value, our algorithm may require
# the gradient of this constraint cost function.
#
#  grad(C) = [dC/dx1, dC/dx2, dC/dx3 ...]
#
# In calculating this, a lot of expensive floating point
# calculations from the original function calculations.
# As such, we provide an array to store them.

constraintWork = createFloat64Array(20)

# The constraint has a guarentee that we won't request
# the gradient without calling the original function
# first. It has a further guarentee that nothing besides
# it will be concerned with the contents of
# `constraintWork`.
#
# Once we calculate their partial derivatives, we don't
# want to have to allocate memory to pass them back.
# As such, we provide an array for them to be loaded into.

constraintGradient        = createFloat64Array(20)

# But we could potentially have more that 20 variables,
# and so more than 20 partial derivatives, right?
#
# Yes, but the constraint will only involve
# a few of those variables, so most derivatives are 0.
# If we stored all of them, `constraintGradient`
# would look like:
#
#   [0, 0, 0, 1.3, 0, 0, -0.3, 0, 0, 0, 0 ...]
#
# which would both be a waste of space and computation
# when we iterate over it.
#
# So we only store partial derivatives for variables
# the constraint is concerned with.
#
# To make use of them, we need to know which variables
# it is that the constraint is referring to.
#
# constraintVars are pointers to the ids of each
# constraint involved in the calculation (more on this
# below)
constraintVars            = createIDsArray(20)

# Vars is the `currentState` indices of the variables this
# constraint is concerned with. They are in the same
# order as the partial derivatives mentioned earlier.
#
# For example, they might look like:
#
#  constraintGradient = [dC/x3, dC/x9, dC/x5 ...]
#  constraintVars     = [    3,     9,     5 ...]
#
#  currentState   = [x0, x1, x2, x3, x4, x5, x6, x7 ...]
#                          ^^      ^^
#                          3       5
#

constraintConstructors =
  # Let's make some constraints!!!
  #
  # We'll start with a very simple constraint, the
  # distance constraint.
  #
  # We want a function generate them
  distance: (aID, bID, dist) ->

    # The `distance` constraint fixes the
    # distance between two points.

    # First, we convert from the external
    # id representation to something more
    # usable

    aBase = 2*pointIDs.indexOf(aID)
    bBase = 2*pointIDs.indexOf(bID)
    constraint = {}

    # The cost function:
    # it always retunrs a value >= 0
    # 0 is perfect satisfaction of the constraint.
    # The higher it is, the worse a solution it is.
    constraint.cost = () ->

      # We calculate a few things
      dx = currentState[aBase]     - currentState[bBase]
      dy = currentState[aBase + 1] - currentState[bBase + 1]
      pre_cost = dx*dx + dy*dy - dist*dist

      # We store the nice things in
      # `constraintWork` for later use!
      constraintWork[0] = dx
      constraintWork[1] = dy
      constraintWork[2] = pre_cost

      # And finish!
      return 10*Math.abs(pre_cost)/dist/dist

    # Sets `constraintVars` and `constraintGradient`
    # and then returns the length.

    constraint.deriv_iter_setup = () ->

      # Tell the world about the indices
      # of our variables!
      constraintVars[0] = aBase
      constraintVars[1] = aBase + 1
      constraintVars[2] = bBase
      constraintVars[3] = bBase + 1

      # Load stuff from constraintWork
      dx       = constraintWork[0]
      dy       = constraintWork[1]
      pre_cost = constraintWork[2]

      # deriv constant
      k = 10*2/dist/dist

      # Set the gradient
      if pre_cost > 0
        constraintGradient[0] =  k*dx
        constraintGradient[1] =  k*dy
        constraintGradient[2] = -k*dx
        constraintGradient[3] = -k*dy
      else
        constraintGradient[0] = -k*dx
        constraintGradient[1] = -k*dy
        constraintGradient[2] =  k*dx
        constraintGradient[3] =  k*dy

      return 4 # number of variables

    return constraint


  angle: (aID, cID, bID, angle) ->

    # The `angle` constraint fixes the
    # angle of ACB<, (c for center).

    aBase = 2*pointIDs.indexOf(aID)
    bBase = 2*pointIDs.indexOf(bID)
    cBase = 2*pointIDs.indexOf(cID)

    [cos, sin] = [Math.cos(angle), Math.sin(angle)]

    constraint = {}

    # The cost function
    constraint.cost = () ->
      # How far from the desired angle are we?
      #
      #         [ s  -c ]
      #   (a-b) [ c   s ] (c-b)
      #   ---------------------
      #   ||a-b||   *   ||c-b||
      #
      # The numerator is a quadratic form
      #

      # We calculate a few things
      [a1, a2] = [currentState[aBase], currentState[aBase + 1]]
      [b1, b2] = [currentState[bBase], currentState[bBase + 1]]
      [c1, c2] = [currentState[cBase], currentState[cBase + 1]]

      [p1, p2] = [a1 - c1,  a2 - c2]
      [q1, q2] = [b1 - c1,  b2 - c2]

      angleProd  = sin*p1*q1 - cos*p1*q2 + cos*p2*q1 + sin*p2*q2
      cost = Math.sqrt(angleProd*angleProd/ (q1*q1+q2*q2) / (p1*p1+p2*p2))

      # We store the nice things in
      # `constraintWork` for later use!
      constraintWork[0] = cost

      # And finish!
      return cost

    # Sets `constraintVars` and `constraintGradient`
    # and then returns the length.

    constraint.deriv_iter_setup = () ->

      # Tell the world about the indices
      # of our variables!
      constraintVars[0] = aBase
      constraintVars[1] = aBase + 1
      constraintVars[2] = cBase
      constraintVars[3] = cBase + 1
      constraintVars[4] = bBase
      constraintVars[5] = bBase + 1

      # Load stuff from constraintWork
      cost       = constraintWork[0]

      for n in [0..5]
        currentState[constraintVars[n]] += 0.001
        cost2 = constraint.cost()
        currentState[constraintVars[n]] -= 0.001
        constraintGradient[constraintVars[n]] = (cost2 - cost)/0.001

      return 6 # number of variables

    return constraint


  coradial: (params) ->

    aID = params.pointIDs[0]
    cID = params.centerID
    bID = params.pointIDs[1]

    # The `angle` constraint fixes the
    # angle of ACB<, (c for center).

    aBase = 2*pointIDs.indexOf(aID)
    bBase = 2*pointIDs.indexOf(bID)
    cBase = 2*pointIDs.indexOf(cID)

    constraint = {}

    # The cost function
    constraint.cost = () ->
      # How far from the desired angle are we?
      #
      #         [ s  -c ]
      #   (a-b) [ c   s ] (c-b)
      #   ---------------------
      #   ||a-b||   *   ||c-b||
      #
      # The numerator is a quadratic form
      #

      # We calculate a few things
      [a1, a2] = [currentState[aBase], currentState[aBase + 1]]
      [b1, b2] = [currentState[bBase], currentState[bBase + 1]]
      [c1, c2] = [currentState[cBase], currentState[cBase + 1]]

      [p1, p2] = [a1 - c1,  a2 - c2]
      [q1, q2] = [b1 - c1,  b2 - c2]

      [lenp, lenq] = [Math.sqrt(p1*p1 + p2*p2), Math.sqrt(q1*q1 + q2*q2)]

      cost = 15*Math.abs(lenp - lenq)/(lenp + lenq)

      # We store the nice things in
      # `constraintWork` for later use!
      constraintWork[0] = cost
      constraintWork[1] = lenp
      constraintWork[2] = lenq
      constraintWork[3] = p1
      constraintWork[4] = p2
      constraintWork[5] = q1
      constraintWork[6] = q2

      # And finish!
      return cost

    # Sets `constraintVars` and `constraintGradient`
    # and then returns the length.

    constraint.deriv_iter_setup = () ->

      # Tell the world about the indices
      # of our variables!
      constraintVars[0] = aBase
      constraintVars[1] = aBase + 1
      constraintVars[2] = cBase
      constraintVars[3] = cBase + 1
      constraintVars[4] = bBase
      constraintVars[5] = bBase + 1

      # # Load stuff from constraintWork
      cost       = constraintWork[0]
      lenp       = constraintWork[1]
      lenq       = constraintWork[2]
      p1         = constraintWork[3]
      p2         = constraintWork[4]
      q1         = constraintWork[5]
      q2         = constraintWork[6]


      #What do derivatives of our function look like?
      #
      # d   |p| - |q|            4       (
      # --  ----------  =  ------------- (
      # dx  |p| + |q|      (|p| + |q|)^2 (
      #
      #              |p| (    dq1      dq2 )
      #              --- ( q1 --- + q2 --- )
      #              |q| (    dx        dx )
      #
      #
      #              |q| (    dp1      dp2 )  )
      #           -  --- ( p1 --- + p2 --- )  )
      #              |p| (    dx        dx )  )
      #
      #
      # For a1, a2, b1, and b2, only one derivative will be 1, the rest 0.
      #
      # For c1 or c2, either the 1 component or 2 compoenent derivatives will be -1,
      # and the other 2 will be 0.
      #
      # REMEMBER: The actual function has an abs around it. So if cost<0, multiply by -1.

      # We'd like to re-use as many computations as possible.
      #
      # First, the gigantic constant at the beginning.
      #
      # We take this opportunity to account for the abs value

      base = lenp + lenq
      base = base*base     # (|p| + |q|)^2

      if cost > 0
        K = 15*4.0 / base
      else
        K = -15*4.0 / base

      # Actually, lets multiply it out into the p/q or q/p ratios
      # We'll talk about them in terms of the derivatives for q or p

      Kq = K*lenp/lenq
      Kp = K*lenq/lenp

      # That leaves us with:
      #
      # d   |p| - |q|
      # --  ----------  =
      # dx  |p| + |q|
      #
      #            (    dq1      dq2 )
      #         Kq ( q1 --- + q2 --- )
      #            (    dx        dx )
      #
      #
      #            (    dp1      dp2 )
      #     +   Kp ( p1 --- + p2 --- )
      #            (    dx        dx )
      #

      # Actually, we can go one step further, and distribute one more time.
      # This makes sense, since we will reuse our work more.

      Kq1 = Kq * q1
      Kq2 = Kq * q2
      Kp1 = Kp * p1
      Kp2 = Kp * p2

      #
      # d   |p| - |q|
      # --  ----------  =
      # dx  |p| + |q|
      #
      #          dq1         dq2         dp1         dp2
      #      Kq1 ---  +  Kq2 ---  +  Kp1 ---  +  Kp2 ---
      #          dx          dx          dx          dx

      constraintGradient[aBase  ] = Kp1
      constraintGradient[aBase+1] = Kp2
      constraintGradient[bBase  ] = Kq1
      constraintGradient[bBase+1] = Kq2
      constraintGradient[cBase  ] = -(Kp1+Kq1)
      constraintGradient[cBase+1] = -(Kp2+Kq2)


      # for n in [0..5]
      #   #constraintVars[constraintVars[n]] = 0
      #   # currentState[constraintVars[n]] += 0.001
      #   # cost2 = constraint.cost()
      #   # currentState[constraintVars[n]] -= 0.001
      #   # constraintGradient[constraintVars[n]] = (cost2 - cost)/0.001
      #   #console.log cost, cost2, (cost2 - cost)/0.001

      # console.log "grad (numerical):",
      #   constraintGradient[aBase],
      #   constraintGradient[aBase+1],
      #   constraintGradient[bBase]
      # console.log "grad (symbolic):",
      #   Kp1,
      #   Kp2,
      #   Kq1

      return 6 # number of variables

    return constraint




constraints = []

locked = []

refine_target = 0.0001

resolve = () ->
  currentStateMod.set(currentState)
  for iterN in [0 .. 1000000]
    satisfied=true
    for c in constraints
      val = c.cost()
      #console.log "constraint cost:", val
      if true # val > 0.001
        satisfied = false
        iter_len = c.deriv_iter_setup()
        for n in [0 .. iter_len - 1]
          pos = constraintVars[n]
          # TODO: Make the constant bigger 3.0ish
          currentStateMod[pos] -= 0.6*val*constraintGradient[pos]
          #currentStateMod[pos] -= 0.001*(currentState[pos] - initialState[s])
    break if satisfied
    currentState.set(currentStateMod)
  if satisfied
    message_changes()
  else
    console.log "failed to solve!"
    message_changes()
  #  settimeout(resvolve, 0)

message_changes = () ->
  diff = []
  for n in [0.. nPoints - 1]
    dx = Math.abs(currentState[2*n    ] - initialState[n    ])
    dy = Math.abs(currentState[2*n + 1] - initialState[n + 1])
    if dx + dy > 0.01
      diff.push {id: pointIDs[n], x: currentState[2*n], y: currentState[2*n + 1]}
  self.postMessage {type: "diff", diff: diff}

receiveDiff = (event) ->
  if event.type == "add_point"
    nPoints += 1
    pointIndex = 2*nPoints - 2
    supportMorePoints() if nPoints >= nPointsTotal
    currentState[pointIndex    ] = event.x
    currentState[pointIndex + 1] = event.y
    pointIDs.push event.id
  if event.type == "add_constraint"
    constraint = constraintConstructors[event.constraint.type](event.constraint)
    constraints.push(constraint)
  if event.type == "move_point"
    n = pointIDs.indexOf(event.id)
    return if n == -1
    pointIndex = 2*n
    currentState[pointIndex    ] = event.x
    currentState[pointIndex + 1] = event.y
  if event.type == "rm_point"
    nPoints -= 1
    n = pointIDs.indexOf(event.id)
    return if n == -1
    pointIDs.splice(n,1)
    currentState.set(currentState.subarray(2*n+2), 2*n)

self.onmessage = (event) ->
  receiveDiff(diff) for diff in event.data
  resolve()

# Testing!!!

# receiveDiff({type: "add_point", x: 0, y: 0, id: 331 })
# receiveDiff({type: "add_point", x: 1, y: 1, id: 332 })
# receiveDiff({type: "add_point", x: 2, y: 2, id: 525 })
# receiveDiff({type: "add_constraint", constraint: distance(331, 332, 30)})
# #receiveDiff({type: "add_constraint", constraint: distance(332, 525, 10)})
# receiveDiff({type: "add_constraint", constraint: coradial(331,332, 525)})
# #receiveDiff({type: "add_point", x: 2, y: 2, id: 527 })
# #receiveDiff({type: "move_point", x: 5, y: -5, id: 331 })

# resolve()
