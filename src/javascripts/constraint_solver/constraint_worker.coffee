# A Worker for geometric constraint solving!!

# #isWorker = (self.document == undefined)
# isWorker = true

# # If we aren't a worker, this code will instead give us the URL to create the worker!

# if !isWorker

#   webWorkerFn = arguments.callee
#   _webWorkerURL = undefined
#   # Getting a blob url reference to this script's closure
#   webWorkerURL = ->
#     return _webWorkerURL if _webWorkerURL?
#     # Removing the closure from the worker's js because it caused syntax issues in chrome 24
#     str = webWorkerFn.toString()
#     str = str.replace(/^\s*function\s*\(\) {/, "").replace(/}\s*$/, '')

#     webWorkerBlob = new Blob [str], type: "text/javascript"
#     _webWorkerURL = (window.URL || window.webkitURL).createObjectURL webWorkerBlob

#   return


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
pointArrayF = (nVar) -> return new Float64Array(new ArrayBuffer(8*nVar))
pointArrayUI= (nVar) -> return new  Uint16Array(new ArrayBuffer(2*nVar))

# The number of points we initial make room for
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

initial   = pointArrayF (2*nPointsTotal)

# The constraint solvers last step state

varmap    = pointArrayF (2*nPointsTotal)

# Working space

varmapMod = pointArrayF (2*nPointsTotal)



# If we ever need more points than nPointsTotal...
supportMorePoints = () ->
  nPointsTotal *= 2
  varmap    = pointArrayF (2*nPointsTotal)
  varmapMod = pointArrayF (2*nPointsTotal)
  initial   = pointArrayF (2*nPointsTotal)



# For tracking external references to points.
# For example, to find the x component of
# a point of a certain id:
#
#   varmap[2*pointIDs.indexOf(id)]
#
# You can get y by adding 1

pointIDs      = []

# The same idea iwth constraints!

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

constraint_work = pointArrayF(20)

# The constraint has a guarentee that we won't request
# the gradient without calling the original function
# first. It has a further guarentee that nothing besides
# it will be concerned with the contents of
# `constraint_work`.
#
# Once we calculate ther partial derivatives, we don't
# want to have to allocate memory to pass them back.
# As such, we provide an array for them to be loaded into.

constraint_gradient        = pointArrayF(20)

# But we could potentially have more that 20 variables,
# and so more than 20 partial derivatives, right?
#
# Yes, but the constraint will only involve
# a few of those variables, so most derivatives are 0.
# If we stored all of them, `constraint_gradient`
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

constraint_vars            = pointArrayUI(20)

# Vars is the `varmap` indices of the variables this
# constraint is concerned with. They are in the same
# order as the partial derivatives mentioned earlier.
#
# For example, they might look like:
#
#  constraint_gradient = [dC/x3, dC/x9, dC/x5 ...]
#  constraint_vars     = [    3,     9,     5 ...]
#
#  varmap   = [x0, x1, x2, x3, x4, x5, x6, x7 ...]
#                          ^^      ^^
#                          3       5
#

# Let's make some constraints!!!
#
# We'll start with a very simple constraint, the
# distance constraint.
#
# We want a function generate them

distance = (aID, bID, dist) ->

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
    dx = varmap[aBase]     - varmap[bBase]
    dy = varmap[aBase + 1] - varmap[bBase + 1]
    pre_cost = dx*dx + dy*dy - dist*dist

    # We store the nice things in
    # `constraint_work` for later use!
    constraint_work[0] = dx
    constraint_work[1] = dy
    constraint_work[2] = pre_cost

    # And finish!
    return 10*Math.abs(pre_cost)/dist/dist

  # Sets `constraint_vars` and `constraint_gradient`
  # and then returns the length.

  constraint.deriv_iter_setup = () ->

    # Tell the world about the indices
    # of our variables!
    constraint_vars[0] = aBase
    constraint_vars[1] = aBase + 1
    constraint_vars[2] = bBase
    constraint_vars[3] = bBase + 1

    # Load stuff from constraint_work
    dx       = constraint_work[0]
    dy       = constraint_work[1]
    pre_cost = constraint_work[2]

    # deriv constant
    k = 10*2/dist/dist

    # Set the gradient
    if pre_cost > 0
      constraint_gradient[0] =  k*dx
      constraint_gradient[1] =  k*dy
      constraint_gradient[2] = -k*dx
      constraint_gradient[3] = -k*dy
    else
      constraint_gradient[0] = -k*dx
      constraint_gradient[1] = -k*dy
      constraint_gradient[2] =  k*dx
      constraint_gradient[3] =  k*dy

    return 4 # number of variables

  return constraint


angle = (aID, cID, bID, angle) ->

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
    [a1, a2] = [varmap[aBase], varmap[aBase + 1]]
    [b1, b2] = [varmap[bBase], varmap[bBase + 1]]
    [c1, c2] = [varmap[cBase], varmap[cBase + 1]]

    [p1, p2] = [a1 - c1,  a2 - c2]
    [q1, q2] = [b1 - c1,  b2 - c2]

    angleProd  = sin*p1*q1 - cos*p1*q2 + cos*p2*q1 + sin*p2*q2
    cost = Math.sqrt(angleProd*angleProd/ (q1*q1+q2*q2) / (p1*p1+p2*p2))

    # We store the nice things in
    # `constraint_work` for later use!
    constraint_work[0] = cost

    # And finish!
    return cost

  # Sets `constraint_vars` and `constraint_gradient`
  # and then returns the length.

  constraint.deriv_iter_setup = () ->

    # Tell the world about the indices
    # of our variables!
    constraint_vars[0] = aBase
    constraint_vars[1] = aBase + 1
    constraint_vars[2] = cBase
    constraint_vars[3] = cBase + 1
    constraint_vars[4] = bBase
    constraint_vars[5] = bBase + 1

    # Load stuff from constraint_work
    cost       = constraint_work[0]

    for n in [0..5]
      varmap[constraint_vars[n]] += 0.001
      cost2 = constraint.cost()
      varmap[constraint_vars[n]] -= 0.001
      constraint_gradient[constraint_vars[n]] = (cost2 - cost)/0.001

    return 6 # number of variables

  return constraint


coradial = (aID, cID, bID) ->

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
    [a1, a2] = [varmap[aBase], varmap[aBase + 1]]
    [b1, b2] = [varmap[bBase], varmap[bBase + 1]]
    [c1, c2] = [varmap[cBase], varmap[cBase + 1]]

    [p1, p2] = [a1 - c1,  a2 - c2]
    [q1, q2] = [b1 - c1,  b2 - c2]

    [lenp, lenq] = [Math.sqrt(p1*p1 + p2*p2), Math.sqrt(q1*q1 + q2*q2)]

    cost = 15*Math.abs(lenp - lenq)/(lenp + lenq)

    # We store the nice things in
    # `constraint_work` for later use!
    constraint_work[0] = cost
    constraint_work[1] = lenp
    constraint_work[2] = lenq
    constraint_work[3] = p1
    constraint_work[4] = p2
    constraint_work[5] = q1
    constraint_work[6] = q2

    # And finish!
    return cost

  # Sets `constraint_vars` and `constraint_gradient`
  # and then returns the length.

  constraint.deriv_iter_setup = () ->

    # Tell the world about the indices
    # of our variables!
    constraint_vars[0] = aBase
    constraint_vars[1] = aBase + 1
    constraint_vars[2] = cBase
    constraint_vars[3] = cBase + 1
    constraint_vars[4] = bBase
    constraint_vars[5] = bBase + 1

    # # Load stuff from constraint_work
    cost       = constraint_work[0]
    lenp       = constraint_work[1]
    lenq       = constraint_work[2]
    p1         = constraint_work[3]
    p2         = constraint_work[4]
    q1         = constraint_work[5]
    q2         = constraint_work[6]


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

    constraint_gradient[aBase  ] = Kp1
    constraint_gradient[aBase+1] = Kp2
    constraint_gradient[bBase  ] = Kq1
    constraint_gradient[bBase+1] = Kq2
    constraint_gradient[cBase  ] = -(Kp1+Kq1)
    constraint_gradient[cBase+1] = -(Kp2+Kq2)


    # for n in [0..5]
    #   #constraint_vars[constraint_vars[n]] = 0
    #   # varmap[constraint_vars[n]] += 0.001
    #   # cost2 = constraint.cost()
    #   # varmap[constraint_vars[n]] -= 0.001
    #   # constraint_gradient[constraint_vars[n]] = (cost2 - cost)/0.001
    #   #console.log cost, cost2, (cost2 - cost)/0.001

    # console.log "grad (numerical):",
    #   constraint_gradient[aBase],
    #   constraint_gradient[aBase+1],
    #   constraint_gradient[bBase]
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
  varmapMod.set(varmap)
  for iterN in [0 .. 1000000]
    satisfied=true
    for c in constraints
      val = c.cost()
      #console.log "constraint cost:", val
      if true # val > 0.001
        satisfied = false
        iter_len = c.deriv_iter_setup()
        for n in [0 .. iter_len - 1]
          pos = constraint_vars[n]
          # TODO: Make the constant bigger 3.0ish
          varmapMod[pos] -= 0.6*val*constraint_gradient[pos]
          #varmapMod[pos] -= 0.001*(varmap[pos] - initial[pos])
    break if satisfied
    varmap.set(varmapMod)
  if satisfied
    message_changes()
  else
    console.log "failed to solve!"
    message_changes()
  #  settimeout(resvolve, 0)

message_changes = () ->
  diff = []
  for n in [0.. nPoints - 1]
    dx = Math.abs(varmap[2*n    ] - initial[2*n    ])
    dy = Math.abs(varmap[2*n + 1] - initial[2*n + 1])
    if dx + dy > 0.01
      diff.push {id: pointIDs[n], x: varmap[2*n], y: varmap[2*n + 1]}
  self.postMessage {type: "diff", diff: diff}

receiveDiff = (event) ->
  if event.type == "add_point"
    nPoints += 1
    pointIndex = 2*nPoints - 2
    supportMorePoints() if nPoints >= nPointsTotal
    varmap[pointIndex    ] = event.x
    varmap[pointIndex + 1] = event.y
    pointIDs.push event.id
  if event.type == "add_constraint"
    constraints.push event.constraint
  if event.type == "move_point"
    n = pointIDs.indexOf(event.id)
    return if n == -1
    pointIndex = 2*n
    varmap[pointIndex    ] = event.x
    varmap[pointIndex + 1] = event.y
  if event.type == "rm_point"
    nPoints -= 1
    n = pointIDs.indexOf(event.id)
    return if n == -1
    pointIDs.splice(n,1)
    varmap.set(varmap.subarray(2*n+2), 2*n)

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
