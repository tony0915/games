local RayCastDemoScene = class("RayCastDemoScene", cc.load("mvc").ViewBase)
local VisibleRect = import("..utils.VisibleRect")

local MATERIAL_DEFAULT = cc.PhysicsMaterial(0.1, 0.5, 0.5)
local STATIC_COLOR = cc.c4f(1.0, 0.0, 0.0, 1.0)

local function makePolygon()
	local drawNode = cc.DrawNode:create()

    local points = {cc.p(-100, -100), cc.p(-100, 100), cc.p(100, 200), cc.p(100, -90)}
        
    drawNode:drawPolygon(points, table.getn(points), cc.c4f(1,1,1,0.5), 1, cc.c4f(0,0,0,1))

    local body = cc.PhysicsBody:createPolygon(points, MATERIAL_DEFAULT)
    drawNode:setPhysicsBody(body)

	return drawNode
end

local function makeBall(layer, point, radius, material)
    material = material or MATERIAL_DEFAULT

    local ball
    if layer.ball then
       ball = cc.Sprite:createWithTexture(layer.ball:getTexture())
    else
       ball = cc.Sprite:create("Images/ball.png")
    end

    ball:setScale(0.13 * radius)

    local body = cc.PhysicsBody:createCircle(ball:getContentSize().width / 2, material)
    ball:setPhysicsBody(body)
    ball:setPosition(point)

    return ball
end

local function makeBox(point, size, color, material)
    material = material or MATERIAL_DEFAULT

    local yellow = false
    if color == 0 then
        yellow = math.random() > 0.5
    else
        yellow = color == 1
    end

    local box = yellow and cc.Sprite:create("Images/YellowSquare.png") or cc.Sprite:create("Images/CyanSquare.png")
    
    box:setScaleX(size.width/100.0)
    box:setScaleY(size.height/100.0)
    
    local body = cc.PhysicsBody:createBox(box:getContentSize(), material)
    box:setPhysicsBody(body)
    box:setPosition(cc.p(point.x, point.y))
    
    return box
end

local function makeTriangle(point, size, color, material)
    material = material or MATERIAL_DEFAULT

    local yellow = false
    if color == 0 then
        yellow = math.random() > 0.5
    else
        yellow = color == 1
    end
    local triangle = yellow and cc.Sprite:create("Images/YellowTriangle.png") or cc.Sprite:create("Images/CyanTriangle.png")
    
    if size.height == 0 then
        triangle:setScale(size.width/100.0)
    else
        triangle:setScaleX(size.width/50.0)
        triangle:setScaleY(size.height/43.5)
    end

    local vers = { cc.p(0, triangle:getContentSize().height/2),
             cc.p(triangle:getContentSize().width/2, -triangle:getContentSize().height/2),
             cc.p(-triangle:getContentSize().width/2, -triangle:getContentSize().height/2)
           }

    local body = cc.PhysicsBody:createPolygon(vers, material)
    triangle:setPhysicsBody(body)
    triangle:setPosition(point)
    
    return triangle
end

local function PhysicsDemoRayCast()
    local layer = cc.Layer:create()

    local function onEnter()

    	local polygon1 = makePolygon()
    	polygon1:setPosition(cc.p(300, 300))
    	layer:addChild(polygon1)

       local function onTouchEnded(touch, event)
	         local location = touch:getLocation()
	  
	         -- local r = math.random(3)
	         -- if r ==1 then
	         --     layer:addChild(makeBall(layer, location, 5 + math.random()*10))
	         -- elseif r == 2 then
	         --     layer:addChild(makeBox(location, cc.size(10 + math.random()*15, 10 + math.random()*15)))
	         -- elseif r == 3 then
	         --     layer:addChild(makeTriangle(location, cc.size(10 + math.random()*20, 10 + math.random()*20)))
	         -- end
       end
       
       local touchListener = cc.EventListenerTouchOneByOne:create()
       touchListener:registerScriptHandler(function() return true end, cc.Handler.EVENT_TOUCH_BEGAN)
       touchListener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
       local eventDispatcher = layer:getEventDispatcher()
       eventDispatcher:addEventListenerWithSceneGraphPriority(touchListener, layer)
       
       cc.Director:getInstance():getRunningScene():getPhysicsWorld():setGravity(cc.p(0,0))
       
       local node = cc.DrawNode:create()
       node:setPhysicsBody(cc.PhysicsBody:createEdgeSegment(cc.p(VisibleRect:leftBottom().x, 
                                                                 VisibleRect:leftBottom().y + 50), 
                                                            cc.p(VisibleRect:rightBottom().x, 
                                                                 VisibleRect:rightBottom().y + 50)))
       node:drawSegment(cc.p(VisibleRect:leftBottom().x, VisibleRect:leftBottom().y + 50), 
                        cc.p(VisibleRect:rightBottom().x, VisibleRect:rightBottom().y + 50), 
                        1, 
                        STATIC_COLOR)
       layer:addChild(node)

       local mode = 0
       cc.MenuItemFont:setFontSize(18)
       local item = cc.MenuItemFont:create("Toogle debugChange Mode(any)")
       local function changeModeCallback(sender)
	         mode = (mode + 1) % 3
	  
	         if mode == 0 then
	             item:setString("Change Mode(any)")
	         elseif mode == 1 then
	             item:setString("Change Mode(nearest)")
	         elseif mode == 2 then
	         item:setString("Change Mode(multiple)")
	         end
       end
       
       item:registerScriptTapHandler(changeModeCallback)
       
       local menu = cc.Menu:create(item)
       layer:addChild(menu)
       menu:setPosition(cc.p(VisibleRect:left().x+100, VisibleRect:top().y-10))

       local angle = 0
       local drawNode = nil
       local function update(delta)
	         local L = 250.0
	         local point1 = VisibleRect:center()
	         local d = cc.p(L * math.cos(angle), L * math.sin(angle))
	         local point2 = cc.p(point1.x + d.x, point1.y + d.y)
    
          if drawNode then layer:removeChild(drawNode) end
          drawNode = cc.DrawNode:create()
          if mode == 0 then
	            local point3 = cc.p(point2.x, point2.y)
	            local function func(world, info)
		              point3 = info.contact
		              return false
	            end

              cc.Director:getInstance():getRunningScene():getPhysicsWorld():rayCast(func, point1, point2)
              drawNode:drawSegment(point1, point3, 1, STATIC_COLOR)
            
              if point2.x ~= point3.x or point2.y ~= point3.y then
	               drawNode:drawDot(point3, 2, cc.c4f(1.0, 1.0, 1.0, 1.0))
              end
              layer:addChild(drawNode)
	        elseif mode == 1 then
	            local point3 = cc.p(point2.x, point2.y)
              local friction = 1.0
              local function func(world, info)
                  if friction > info.fraction then
                      point3 = info.contact
                      friction = info.fraction
		              end
                  return true
              end
            
              cc.Director:getInstance():getRunningScene():getPhysicsWorld():rayCast(func, point1, point2)
              drawNode:drawSegment(point1, point3, 1, STATIC_COLOR)
            
              if point2.x ~= point3.x or point2.y ~= point3.y then
                  drawNode:drawDot(point3, 2, cc.c4f(1.0, 1.0, 1.0, 1.0))
              end
              layer:addChild(drawNode)
          elseif mode == 2 then
	            local points = {}
            
              local function func(world, info)
                  points[#points + 1] = info.contact
                  return true
              end
            
              cc.Director:getInstance():getRunningScene():getPhysicsWorld():rayCast(func, point1, point2)
              drawNode:drawSegment(point1, point2, 1, STATIC_COLOR)
            
              for _, p in ipairs(points) do
                  drawNode:drawDot(p, 2, cc.c4f(1.0, 1.0, 1.0, 1.0))
              end
            
              layer:addChild(drawNode)
          end
    
         angle = angle + 0.25 * math.pi / 180.0

      end

       layer:scheduleUpdateWithPriorityLua(update, 0)
    end

   	local function onNodeEvent(event)
        if "enter" == event then
            onEnter()
        end
    end
    layer:registerScriptHandler(onNodeEvent)

    return layer
end


function RayCastDemoScene:onCreate()

	local layer = PhysicsDemoRayCast():addTo(self)
	print("RayCastDemoScene onCreate!!!!!!!")
end


return RayCastDemoScene