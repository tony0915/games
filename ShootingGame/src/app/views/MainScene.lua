
local MainScene = class("MainScene", cc.load("mvc").ViewBase)

local VisibleRect = import("..utils.VisibleRect")

local function range(from, to, step)
  step = step or 1
  return function(_, lastvalue)
    local nextvalue = lastvalue + step
    if step > 0 and nextvalue <= to or step < 0 and nextvalue >= to or
       step == 0
    then
      return nextvalue
    end
  end, nil, from - step
end

local function PhysicsDemoSlice()
    local layer = cc.Layer:create()
    
    print("cc.PhysicsWorld.DEBUGDRAW_ALL: "..tostring(cc.PhysicsWorld.DEBUGDRAW_ALL))
   	local function toggleDebugCallback(sender)
      cc.Director:getInstance():getRunningScene():getPhysicsWorld():setDebugDrawMask( cc.PhysicsWorld.DEBUGDRAW_ALL) --or cc.PhysicsWorld.DEBUGDRAW_NONE)
   	end

   	layer.toggleDebug = function(self) toggleDebugCallback(nil) end

    local function onEnter()
      layer:toggleDebug()
      local sliceTag = 1

      print("onEnter called!!!!!!!!!")
      local function clipPoly(shape, normal, distance)
        local body = shape:getBody()
        local count = shape:getPointsCount()
        local points = {}
    
        local j = count - 1
        for i in range(0, count-1) do
          local a = body:local2World(shape:getPoint(j))
          local aDist = cc.pDot(a, normal) - distance
        
          if aDist < 0.0 then
            points[#points + 1] = a
          end
        
          local b = body:local2World(shape:getPoint(i))
          local bDist = cc.pDot(b, normal) - distance
          
          if aDist*bDist < 0.0 then
              local t = math.abs(aDist)/(math.abs(aDist) + math.abs(bDist))
              points[#points + 1] = cc.pLerp(a, b, t)
          end
          j = i
        end
    
        local center = cc.PhysicsShape:getPolyonCenter(points)
        local node = cc.Node:create()
        local polyon = cc.PhysicsBody:createPolygon(points, 
                                                    cc.PHYSICSBODY_MATERIAL_DEFAULT, 
                                                    cc.p(-center.x, -center.y))
        node:setPosition(center)
        node:setPhysicsBody(polyon)
        polyon:setVelocity(body:getVelocityAtWorldPoint(center))
        polyon:setAngularVelocity(body:getAngularVelocity())
        polyon.tag = sliceTag
        layer:addChild(node)
      end


      local function slice(world, info)
        if info.shape:getBody().tag ~= sliceTag then
          return true
         end
    
        if not info.shape:containsPoint(info.start) and not info.shape:containsPoint(info.ended) then
          local normal = cc.p(info.ended.x - info.start.x, info.ended.y - info.start.y)
          normal = cc.pNormalize(cc.pPerp(normal))
          local dist = cc.pDot(info.start, normal)
        
          clipPoly(info.shape, normal, dist)
          clipPoly(info.shape, cc.p(-normal.x, -normal.y), -dist)
        
          info.shape:getBody():removeFromWorld()
        end
        return true
      end

      local function onTouchEnded(touch, event)
        cc.Director:getInstance():getRunningScene():getPhysicsWorld():rayCast(slice, 
                                                                              touch:getStartLocation(), 
                                                                              touch:getLocation())
      end

      local touchListener = cc.EventListenerTouchOneByOne:create()
      touchListener:registerScriptHandler(function() return true end, cc.Handler.EVENT_TOUCH_BEGAN)
      touchListener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
      local eventDispatcher = layer:getEventDispatcher()
      eventDispatcher:addEventListenerWithSceneGraphPriority(touchListener, layer)
    
      local ground = cc.Node:create()
      ground:setPhysicsBody(cc.PhysicsBody:createEdgeSegment(cc.p(VisibleRect:leftBottom().x, 
                                                                VisibleRect:leftBottom().y + 50), 
                                                           cc.p(VisibleRect:rightBottom().x, 
                                                                VisibleRect:rightBottom().y + 50)))
      layer:addChild(ground)
    
      local box = cc.Node:create()
      local points = {cc.p(-100, -100), cc.p(-100, 100), cc.p(100, 100), cc.p(100, -100)}
      box:setPhysicsBody(cc.PhysicsBody:createPolygon(points))
      box:setPosition(VisibleRect:center())
      box:getPhysicsBody().tag = sliceTag
      layer:addChild(box)
    end



   	local function onNodeEvent(event)
        if "enter" == event then
            onEnter()
        end
    end
    layer:registerScriptHandler(onNodeEvent)

    return layer
end

function MainScene:onCreate()
    -- add background image
    -- display.newSprite("HelloWorld.png")
    --     :move(display.center)
    --     :addTo(self)

    -- -- add HelloWorld label
    -- cc.Label:createWithSystemFont("Hello World", "Arial", 40)
    --     :move(display.cx, display.cy + 200)
    --     :addTo(self)

    PhysicsDemoSlice():addTo(self)
    print("PhysicsDemoSlice added!!!!!!!!!!!!!!!")
end

return MainScene
