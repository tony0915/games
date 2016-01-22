local RayCastDemoScene = class("RayCastDemoScene", cc.load("mvc").ViewBase)
local VisibleRect = import("..utils.VisibleRect")

local MATERIAL_DEFAULT = cc.PhysicsMaterial(0.1, 0.5, 0.5)
local STATIC_COLOR = cc.c4f(1.0, 0.0, 0.0, 1.0)

local function makePolygon(points)
  assert(points and #points>2, "the number of points mustbe greater than 2!")

	local drawNode = cc.DrawNode:create()
        
  drawNode:drawPolygon(points, table.getn(points), cc.c4f(1,1,1,0.5), 1, cc.c4f(0,0,0,1))

  local body = cc.PhysicsBody:createPolygon(points, MATERIAL_DEFAULT)
  drawNode:setPhysicsBody(body)

	return drawNode
end

local function makeCircle()
    local drawNode = cc.DrawNode:create()
    drawNode:drawDot(cc.p(0, 0), 2, cc.c4f(1.0, 1.0, 1.0, 1.0))

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

    local drawNodesLayer = cc.Layer:create()
    layer:addChild(drawNodesLayer)

    local function onEnter()

        local center = makeCircle()
        center:setPosition(cc.p(0, 0))
        layer:addChild(center)

    	  local polygon1 = makePolygon({cc.p(0, 0), cc.p(0, 100), cc.p(100, 100), cc.p(100, 0)})
    	  polygon1:setPosition(cc.p(300, 300))
    	  layer:addChild(polygon1)

        local polygon2 = makePolygon({cc.p(0, 100), cc.p(100, 100), cc.p(150, 0)})
        polygon2:setPosition(cc.p(600, 100))
        layer:addChild(polygon2)
       
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
        menu:setPosition(cc.p(VisibleRect:left().x + 100, VisibleRect:top().y - 10))

        local angle = 0
        local function update(delta)
	         local L = 500.0
	         local point1 = cc.p(center:getPositionX(), center:getPositionY()) --VisibleRect:center()

           drawNodesLayer:removeAllChildren()
          --if drawNode then layer:removeChild(drawNode) end
          for i=1,100 do
            local drawNode = cc.DrawNode:create()
            if mode == 0 then
                local d = cc.p(L * math.cos(angle), L * math.sin(angle))
                local point2 = cc.p(point1.x + d.x, point1.y + d.y)

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
                drawNodesLayer:addChild(drawNode)
                print("drawNode called!!!!!!!!!!!!!!!!!!!!!")
            end

            angle = 2 * math.pi * i/100
          end
        end

      local function onTouchEnded(touch, event)
        local location = touch:getLocation()
        print("location: ", location.x, location.y)
        center:setPosition(cc.p(location.x, location.y))
        update()
      end

      local function onTouchMoved(touch, event)
        print("touch moved!!!!!!!!!!!!!!")
        local location = touch:getLocation()
        center:setPosition(cc.p(location.x, location.y))

        update()
      end

      local touchListener = cc.EventListenerTouchOneByOne:create()
      touchListener:registerScriptHandler(function() return true end, cc.Handler.EVENT_TOUCH_BEGAN)
      touchListener:registerScriptHandler(onTouchMoved, cc.Handler.EVENT_TOUCH_MOVED)
      touchListener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
      local eventDispatcher = layer:getEventDispatcher()
      eventDispatcher:addEventListenerWithSceneGraphPriority(touchListener, layer)

      --layer:scheduleUpdateWithPriorityLua(update, 0)
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