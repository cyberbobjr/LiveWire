-- A resumable circular area cursor. No world or gameplay dependencies: callers
-- own invalidation, scheduling and the meaning of each visited square.
LiveWire = LiveWire or {}
local Scan = {}
LiveWire.SquareScan = Scan

function Scan.new(x, y, z, radius, vertical)
    local r = math.floor(radius)
    return { x = x, y = y, r = r, r2 = radius * radius, dx = -r, dy = -r,
        z = math.max(-32, z - vertical), zmax = math.min(31, z + vertical) }
end

-- The budget bounds cursor positions, including those outside the circle.
function Scan.step(job, budget, visit)
    local n = 0
    while n < budget and job.z <= job.zmax do
        if job.dx * job.dx + job.dy * job.dy <= job.r2 then
            visit(job.x + job.dx, job.y + job.dy, job.z)
        end
        n = n + 1
        job.dy = job.dy + 1
        if job.dy > job.r then
            job.dy, job.dx = -job.r, job.dx + 1
            if job.dx > job.r then job.dx, job.z = -job.r, job.z + 1 end
        end
    end
    return job.z > job.zmax, n
end
