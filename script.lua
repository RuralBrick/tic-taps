-- title:  TICTAPS
-- author: RuralBrick
-- desc:   rhythm game
-- script: lua
DEBUG=false

SCROLL_SPEED=2

VIS_ADJUST=20
AUD_ADJUST=1

NOTE_SPEED=3
TAP_TOLERANCE=2

RESULT_ACCEL=0.1
RESULT_REBOUND=0.2
RESULT_BOUNCES=2

Input={}
Input[1]=01 -- a
Input[2]=19 -- s
Input[3]=04 -- d
Input[4]=06 -- f
Input[5]=10 -- j
Input[6]=11 -- k
Input[7]=12 -- l
Input[8]=42 -- ;
Input.START=  48 -- Space
Input.PAUSE=  48 -- Space
Input.RESTART=18 -- r
Input.SELECT= 05 -- e
Input.QUIT=   17 -- q
Input.AUTO=   15 -- o
Input.DEBUG=  16 -- p

Lane={
	sprite={
		352,354,356,358,360,362,364,366
	},
	light={0,0,0,0,0,0,0,0},
	fade={0,0,0,0,0,0,0,0}
}

State={
	TITLE=0,
	SELECT=1,
	SCROLL=2,
	PLAY=3,
	PAUSE=4,
	END=5,
	RESULT=6
}

gameState=State.TITLE

Scroll={
	UP=-1,
	DOWN=1
}

scrollDir=0
imgY=0


score=0
combo=0
maxCombo=0
stamina=100

tracks={}
currentTrack={}
trackNum=1

tempo=0
bpf=0 --beats per frame
beat=0 --current beat
endBeat=0

ready=false
musicOn=false
resultY=0
resultVel=0
resultBounces=0

Met={
	beat=0,
	interval=0,
	lastClick=0,
	init=function(self)
		self.beat=beat
		self.interval=0
		self.lastClick=0
	end,
	update=function(self,playOver)
		if(beat-1)//4>self.beat then
			self.beat=(beat-1)//4
			self.interval=time()-self.lastClick
			self.lastClick=time()
			if playOver or not musicOn then
				sfx(0,64,2,0)
			end
		end
	end
}

AutoPlay={
	active=false,
	track={},
	init=function(self)
		if self.active then
			self.track={}
			for i,lane in ipairs(currentTrack)do
				for j,note in ipairs(lane)do
					note.lane=i
					table.insert(self.track,note)
				end
			end
		end
	end,
	check=function(self)
		if self.active then
			for i,note in ipairs(self.track)do
				if note.active and
							note.place<beat+1+AUD_ADJUST then
					note.active=false
					score=score+1
					combo=combo+1
					if combo>maxCombo then
						maxCombo=combo
					end
					Lane.fade[note.lane]=3
				end
			end
		end
	end
}

function TIC()

	if gameState==State.TITLE then
		titleTIC()
	elseif gameState==State.SELECT then
		selectTIC()
	elseif gameState==State.SCROLL then
		scrollTIC()
	elseif gameState==State.PLAY then
		playTIC()
	elseif gameState==State.PAUSE then
		pauseTIC()
	elseif gameState==State.END then
		endTIC()
	elseif gameState==State.RESULT then
		resultTIC()
	else
		cls()
		local string="Something went wrong"
		print(string,60,65,15,true)
	end

end

function titleTIC()

	if keyp(Input.START)then
		VIS_ADJUST=20
		AUD_ADJUST=1

		NOTE_SPEED=3

		AutoPlay.active=false
		DEBUG=false

		trackNum=1
		currentTrack=tracks[1]
		gameState=State.SELECT
		sfx(1,"G-5",20)
	end

	cls()
	map(30,0)
	printCtr("Press [Space] to start",91,
										((time()//500)%2)*15)

end

function selectTIC()

	if keyp(Input.START)then
		ready=false
		gameState=State.PLAY
		if key(Input.AUTO)then
			AutoPlay.active=true
		end
		if key(Input.DEBUG)then
			DEBUG=true
		end
	end
	if key(Input[4])then
		scrollDir=Scroll.UP
		imgY=SCROLL_SPEED*Scroll.UP
		gameState=State.SCROLL
		sfx(2,"E-6",10)
	end
	if key(Input[5])then
		scrollDir=Scroll.DOWN
		imgY=SCROLL_SPEED*Scroll.DOWN
		gameState=State.SCROLL
		sfx(2,"E-6",10)
	end
	if keyp(Input[3])then
		NOTE_SPEED=NOTE_SPEED-1
		if NOTE_SPEED<1 then
			NOTE_SPEED=1
		end
	end
	if keyp(Input[6])then
		NOTE_SPEED=NOTE_SPEED+1
	end
	if keyp(Input[2])then
		VIS_ADJUST=VIS_ADJUST-1
	end
	if keyp(Input[7])then
		VIS_ADJUST=VIS_ADJUST+1
	end
	if keyp(Input[1])then
		AUD_ADJUST=AUD_ADJUST-1
	end
	if keyp(Input[8])then
		AUD_ADJUST=AUD_ADJUST+1
	end
	if keyp(Input.QUIT)then
		gameState=State.TITLE
	end

	cls()
	map(0,17)
	drawSelectTxt()

	print(currentTrack.title,112,50)
	print(currentTrack.composer,112,64)

	spr(tracks[wrapListNum(trackNum-1,#tracks)].sprId,24,-36,-1,2,0,0,4,4)
	spr(currentTrack.sprId,24,36,-1,2,0,0,4,4)
	spr(tracks[wrapListNum(trackNum+1,#tracks)].sprId,24,108,-1,2,0,0,4,4)

end

function scrollTIC()

	if keyp(Input[4])then
		scrollDir=Scroll.UP
	elseif keyp(Input[5])then
		scrollDir=Scroll.DOWN
	end

	if imgY<=-72 then
		trackNum=wrapListNum(trackNum-1,#tracks)
		currentTrack=tracks[trackNum]
		gameState=State.SELECT
		return
	elseif imgY>=72 then
		trackNum=wrapListNum(trackNum+1,#tracks)
		currentTrack=tracks[trackNum]
		gameState=State.SELECT
		return
	elseif imgY==0 then
		gameState=State.SELECT
	end

	cls()
	map(0,17)
	drawSelectTxt()

	spr(tracks[wrapListNum(trackNum-2,#tracks)].sprId,
					24,-imgY-108,-1,2,0,0,4,4)
	spr(tracks[wrapListNum(trackNum-1,#tracks)].sprId,
					24,-imgY-36,-1,2,0,0,4,4)
	spr(currentTrack.sprId,
					24,-imgY+36,-1,2,0,0,4,4)
	spr(tracks[wrapListNum(trackNum+1,#tracks)].sprId,
					24,-imgY+108,-1,2,0,0,4,4)
	spr(tracks[wrapListNum(trackNum+2,#tracks)].sprId,
					24,-imgY+180,-1,2,0,0,4,4)

	imgY=imgY+SCROLL_SPEED*scrollDir

end

function playTIC()

	if not ready then
		init()
		ready=true
	end

	if not musicOn and beat>-3 then
		music(currentTrack.id,-1,-1,
								false,true)
		musicOn=true
	end

	for i=1,8 do
		Lane.light[i]=0
		Lane.fade[i]=Lane.fade[i]-1
		if Lane.fade[i]<0 then
			Lane.fade[i]=0
		end
	end

	cls()
	map()

	if beat>0 then
		print("[Space] Pause",152,117)
		if keyp(Input.PAUSE)then
			gameState=State.PAUSE
		end
	end

	if keyp(Input[1])then	checkLane(1)	end
	if keyp(Input[2])then	checkLane(2)	end
	if keyp(Input[3])then	checkLane(3)	end
	if keyp(Input[4])then	checkLane(4)	end
	if keyp(Input[5])then	checkLane(5)	end
	if keyp(Input[6])then	checkLane(6)	end
	if keyp(Input[7])then	checkLane(7)	end
	if keyp(Input[8])then	checkLane(8)	end

	if key(Input[1])then	Lane.light[1]=1 end
	if key(Input[2])then Lane.light[2]=1	end
	if key(Input[3])then	Lane.light[3]=1	end
	if key(Input[4])then	Lane.light[4]=1	end
	if key(Input[5])then	Lane.light[5]=1	end
	if key(Input[6])then	Lane.light[6]=1	end
	if key(Input[7])then	Lane.light[7]=1	end
	if key(Input[8])then	Lane.light[8]=1	end

	AutoPlay:check()

	if beat>endBeat then
		ready=false
		resultY=-136
		resultVel=0
		resultBounces=0
		sfx(1,"C-5",-1,0)
		gameState=State.END
	end

	drawPlayElements()

	if DEBUG then
		print("DOWNBEATS: "..beat//4,0,0)
		print("INTERVAL: "..Met.interval,0,10)
	end

	Met:update(false)
	beat=beat+bpf

end

function pauseTIC()

	music()

	if keyp(Input.PAUSE)then
		local frame=beat//64
		beat=frame*64-3

		gameState=State.PLAY
		music(currentTrack.id,frame,-1,false,true)
	elseif keyp(Input.RESTART)then
		ready=false
		gameState=State.PLAY
	elseif keyp(Input.SELECT)then
		ready=false
		gameState=State.SELECT
		AutoPlay.active=false
		DEBUG=false
	elseif keyp(Input.QUIT)then
		ready=false
		gameState=State.TITLE
		AutoPlay.active=false
		DEBUG=false
	end

	cls()
	printCtr("GAME PAUSED",40,15,false,2)
	line(10,59,230,59,15)
	print("[Space]",20,70)
		print("Resume",60,70)
	print("[R]",20,80)
		print("Restart",60,80)
	print("[E]",20,90)
		print("Return to Song Select",60,90)
	print("[Q]",20,100)
		print("Exit Game",60,100)

end

function endTIC()

	cls()
	map()
	drawPlayElements()
	beat=beat+bpf

	rect(0,resultY,240,136,0)
	drawResultTxt(resultY)
	line(0,136+resultY,240,136+resultY,15)
	resultVel=resultVel+RESULT_ACCEL
	resultY=resultY+resultVel
	if resultY>0 then
		resultY=0
		resultVel=-resultVel*RESULT_REBOUND
		resultBounces=resultBounces+1
		sfx(3,"C-2",8,0,5,1)
		if resultBounces>RESULT_BOUNCES then
			gameState=State.RESULT
		end
	end

end

function resultTIC()

	if keyp(Input.RESTART)then
		gameState=State.PLAY
	elseif keyp(Input.SELECT)then
		gameState=State.SELECT
		AutoPlay.active=false
		DEBUG=false
	elseif keyp(Input.QUIT)then
		gameState=State.TITLE
		AutoPlay.active=false
		DEBUG=false
	end

	cls()
	drawResultTxt()

end

function init()
	endBeat=0

	for i,lane in ipairs(currentTrack)do
		for j,note in ipairs(lane)do
			note.active=true
			if note.place>endBeat then
				endBeat=note.place
			end
		end
	end

	score=0
	combo=0
	maxCombo=0

	bpf=currentTrack.tempo/900
	beat=-19
	endBeat=endBeat+8

	Met:init()
	AutoPlay:init()
	musicOn=false
end

function frameStart(song,num,autoOn)
	gameState=State.PLAY
	currentTrack=tracks[song+1]
	AutoPlay.active=autoOn

	init()

	beat=num*64-3
	music(song,num,-1,false)
	musicOn=true
	ready=true
end

function generateTrack(id,title,
		composer,sprId,tempo,length,arr)
	local track={{},{},{},{},{},{},{},{}}
	local note
	local place
	local frame
	local measure
	for i,data in pairs(arr)do
		if data[1]=='F'then
			frame=data[2]
		elseif data[1]=='M'then
			measure=data[2]
		else
			place=frame*64+
								(measure-1)*16+
									data[1]
			note={
				active=true,
				sprId=Lane.sprite[data[2]],
				place=place
			}

			table.insert(track[data[2]],note)
		end
	end

	track.id=id
	track.title=title
	track.composer=composer
	track.sprId=sprId
	track.tempo=tempo
	track.length=length

	return track
end

function drawSelectTxt()
	local prefix

	print("Calibration",107,4)
	print("Spd: "..NOTE_SPEED,107,14)
	if VIS_ADJUST>0 then prefix="+"
	else prefix="" end
	print("Vid: "..prefix..VIS_ADJUST,147,14)
	if AUD_ADJUST>0 then prefix="+"
	else prefix="" end
	print("Aud: "..prefix..AUD_ADJUST,189,14)

	print("[Space] Choose Song",107,99)
	print("[J] Next",107,106)
	print("[F] Prev",171,106)
	print("[K] Spd+",107,113)
	print("[D] Spd-",107,120)
	print("[L] Vid+",151,113)
	print("[S] Vid-",151,120)
	print("[;] Aud+",192,113)
	print("[A] Aud-",192,120)
	print("[Q] Exit",107,127)

end

function checkLane(lane)
	for i,note in ipairs(currentTrack[lane])do
		if note.place>beat
					-TAP_TOLERANCE+AUD_ADJUST and
					note.place<beat
					+TAP_TOLERANCE+AUD_ADJUST then
			note.active=false
			score=score+1
			combo=combo+1
			if combo>maxCombo then
				maxCombo=combo
			end
			Lane.fade[lane]=3
			break
		end
	end
end

function drawPlayElements()
	drawBarlines()
	drawFades()
	drawNotes()
	drawTargets()
	print("SCORE: "..score,147,11)
	print("COMBO: "..combo,147,18)
	print("MAX COMBO: "..maxCombo,147,25)
end

function drawBarlines()
	local offset=120+VIS_ADJUST+
												4*NOTE_SPEED*((beat-1)%16)
	local y
	for i=0,11 do --makes 3 measures
		y=offset-i*16*NOTE_SPEED

		if i%4==0 then
			line(8,y,135,y,15)
		else
			line(8,y,135,y,10)
		end
	end
end

function drawFades()
	for i=1,8 do
		spr(260+Lane.fade[i]*2,i*16-8,112,
						0,1,0,0,2,2)
	end
end

function drawNotes()
	local offset=112+VIS_ADJUST+
														4*NOTE_SPEED*beat
	local note
	local y
	for lane=1,8 do
		for i=#currentTrack[lane],1,-1 do
			note=currentTrack[lane][i]

			--only draws immediate notes
			if note.active and
						note.place<beat+32 then
				y=offset-4*note.place*NOTE_SPEED
				if y>136 then
					note.active=false
					combo=0	--C-C-Combo Breaker!!
				else
					spr(note.sprId,lane*16-8,y,
									0,1,0,0,2,2)
				end
			end
		end
	end
end

function drawTargets()
	for i=1,8 do
		if Lane.light[i]==1 then
			spr(258,i*16-8,112,0,1,0,0,2,2)
		else
			spr(256,i*16-8,112,0,1,0,0,2,2)
		end
	end
end

function drawResultTxt(y)
	y=y or 0

	printCtr("SONG COMPLETE",15+y,15,false,2)
	line(10,35+y,230,35+y,15)
	print("SCORE:",30,55+y)
	printLft(score,30,55+y)
	print("MAX COMBO:",30,75+y)
	printLft(maxCombo,30,75+y)

	print("[R] Retry",20,115+y)
	printCtr("[E] Song Select",115+y)
	printLft("[Q] Exit",20,115+y)
end

function printCtr(str,y,color,fixed,scale,smallfont)
	y=y or 65
	color=color or 15
	fixed=fixed or false
	scale=scale or 1
	smallfont=smallfont or false
	local width=print(str,0,136,0,fixed,scale,smallfont)
	print(str,(240-width)//2,y,color,fixed,scale,smallfont)
end

function printLft(str,dx,y,color,fixed,scale,smallfont)
	dx=dx or 0
	y=y or 0
	color=color or 15
	fixed=fixed or false
	scale=scale or 1
	smallfont=smallfont or false
	local width=print(str,0,136,0,fixed,scale,smallfont)
	print(str,240-width-dx,y,color,fixed,scale,smallfont)
end

function wrapListNum(num,len)
	while num<1 do
		num=num+len
	end
	while num>len do
		num=num-len
	end
	return num
end

table.insert(tracks,generateTrack(
	0,
	"Megalovania",
	"Toby Fox",
	448,
	120,
	0,
{
{'F',0},
	{'M',1},
		{1,5},
	{'M',2},
		{1,4},
	{'M',3},
		{1,5},
	{'M',4},
		{1,4},
{'F',1},
	{'M',1},
		{1,5},{5,4},
	{'M',2},
		{1,5},{5,4},
	{'M',3},
		{1,5},{5,4},{8,5},{12,4},
	{'M',4},
		{1,1},{3,8},{5,7},
			{8,6},{10,5},{12,4},
		{14,1},{15,2},{16,3},
{'F',2},
	{'M',1},
		{1,5},{2,4},{3,8},{5,7},
			{8,6},{10,5},{12,4},
		{14,1},{15,2},{16,3},
	{'M',2},
		{1,5},{2,4},{3,8},{5,7},
			{8,6},{10,5},{12,4},
		{14,1},{15,2},{16,3},
	{'M',3},
		{1,5},{2,4},{3,8},{5,7},
			{8,6},{10,5},{12,4},
		{14,1},{15,2},{16,3},
	{'M',4},
		{1,5},{2,4},{3,8},{5,7},
			{8,6},{10,5},{12,4},
		{14,1},{15,2},{16,3},
{'F',3},
	{'M',1},
		{1,5},{2,4},{3,8},{5,7},
			{8,6},{10,5},{12,4},
		{14,1},{15,2},{16,3},
	{'M',2},
		{1,5},{2,4},{3,8},{5,7},
			{8,6},{10,5},{12,4},
		{14,1},{15,2},{16,3},
	{'M',3},
		{1,5},{2,4},{3,8},{5,7},
			{8,6},{10,5},{12,4},
		{14,1},{15,2},{16,3},
	{'M',4},
		{1,5},{2,4},{3,8},{5,7},
			{8,6},{10,5},{12,4},
		{14,1},{15,2},{16,3},
{'F',4},
	{'M',1},
		{1,5},{3,4},{4,5},
			{6,4},{8,5},{10,1},{12,1},
	{'M',2},
		{1,5},{3,4},{4,5},
			{6,6},{8,7},{10,6},
		{11,5},{12,1},{13,2},{14,3},
	{'M',3},
		{1,4},{3,5},{4,4},
			{6,5},{8,6},{10,7},{12,8},{14,4},
	{'M',4},
		{1,8},{3,8},
		{5,8},{6,4},{7,8},{8,7},
{'F',5},
	{'M',1},
		{1,7},{3,2},{4,7},{6,2},
			{8,7},{10,4},{12,5},
	{'M',2},
		{1,7},{3,2},{4,7},{6,2},
			{8,4},{10,6},{12,8},
		{14,3},{15,1},
	{'M',3},
		{1,8},{3,6},{5,4},{7,2},
		{9,7},{11,5},{13,3},{15,1},
	{'M',4},
		{1,2},{3,3},{4,4},
			{6,6},{8,8},
{'F',6},
	{'M',1},
		{9,2},{9,6},{10,1},{10,5},
			{11,2},{11,6},{12,3},{12,7},
		{13,4},{13,8},{14,3},{14,7},
			{15,2},{15,6},{16,1},{16,5},
	{'M',2},
		{1,4},{1,8},{2,3},{2,7},{3,1},{3,5},
		{5,2},{5,6},
		{14,5},{16,7},
	{'M',3},
		{1,8},{3,7},{4,6},
		{5,5},{6,4},{7,1},{8,2},
		{9,3},{11,4},{13,5},{14,6},
	{'M',4},
		{1,8},{3,6},
		{5,6},{6,5},{7,4},{8,5},
{'F',7},
	{'M',1},
		{1,1},{1,5},{3,2},{3,6},
			{5,3},{5,7},{7,4},{7,8},
		{9,3},{9,7},{13,2},{13,6},
	{'M',2},
		{1,1},{1,5},{5,2},{5,6},
			{9,3},{9,7},{13,1},{13,5},
	{'M',3},
		{1,4},{1,8},
		{9,8},{10,7},{11,6},{12,5},
			{13,4},{14,3},{15,2},
	{'M',4},
		{1,1},{1,5},
		{9,2},{9,6},
{'F',8},
	{'M',1},
		{9,3},{9,6},{10,4},{10,5},
			{11,3},{11,6},{12,2},{12,7},
		{13,1},{13,8},{14,2},{14,7},
			{15,3},{15,6},{16,4},{16,5},
	{'M',2},
		{1,1},{1,8},{2,2},{2,7},{3,4},{3,5},
		{5,3},{5,6},
		{14,4},{16,2},
	{'M',3},
		{1,1},{3,2},{4,3},
		{5,4},{6,5},{7,8},{8,7},
		{9,6},{11,5},{13,4},{14,3},
	{'M',4},
		{1,1},{3,3},
		{5,3},{6,4},{7,5},{8,4},
{'F',9},
	{'M',1},
		{1,1},{1,8},{3,2},{3,7},
			{5,3},{5,6},{7,4},{7,5},
		{9,3},{9,6},{13,2},{13,7},
	{'M',2},
		{1,1},{1,8},{5,2},{5,7},
			{9,3},{9,6},{13,4},{13,5},
	{'M',3},
		{1,1},{1,8},
		{9,2},{9,7},{10,3},{10,6},
			{11,4},{11,5},{12,3},{12,6},
		{13,2},{13,7},{14,1},{14,8},
			{15,2},{15,7},{16,3},{16,6},
	{'M',4},
		{1,4},{1,5},
		{9,3},{9,6},
{'F',10},
	{'M',1},
		{1,4},{1,5},
		{13,3},{13,6},
	{'M',2},
		{1,2},{1,4},{1,5},{1,7},
		{9,3},{9,4},{9,5},{9,6},
	{'M',3},
		{1,1},{1,3},{1,6},{1,8},
	{'M',4},

{'F',11},
	{'M',1},
		{1,3},
		{13,6},
	{'M',2},
		{1,5},
		{9,4},
	{'M',3},
		{1,1},{1,2},{1,3},{1,4},
			{1,5},{1,6},{1,7},{1,8},
	{'M',4},
		{2,5},{3,4},{4,6},{5,3},
			{6,7},{7,2},{8,8},{9,1},
{'F',12},
	{'M',1},
		{1,1},{1,5},{3,8},{5,7},
			{8,6},{10,5},{12,4},
		{14,1},{15,2},{16,3},
	{'M',2},
		{1,8},{1,4},{3,1},{5,2},
			{8,3},{10,4},{12,5},
		{14,8},{15,7},{16,6},
	{'M',3},
		{1,4},{1,5},{3,1},{3,8},{5,2},{5,7},
		{8,1},{8,8},{10,2},{10,7},{12,3},{12,6},
		{14,4},{14,5},{15,3},{15,6},{16,2},{16,7},
	{'M',4},
		{1,4},{1,5},{3,1},{3,8},{5,2},{5,7},
		{8,1},{8,8},{10,2},{10,7},{12,3},{12,6},
		{14,4},{14,5},{15,3},{15,6},{16,2},{16,7},
{'F',13},
	{'M',1},
		{1,1},{1,5},{3,8},{5,7},
			{8,6},{10,5},{12,4},
		{14,1},{15,2},{16,3},
	{'M',2},
		{1,8},{1,4},{3,1},{5,2},
			{8,3},{10,4},{12,5},
		{14,8},{15,7},{16,6},
	{'M',3},
		{1,1},{1,5},{3,4},{3,8},{5,3},{5,7},
			{8,1},{8,5},{10,3},{10,7},{12,2},{12,6},
		{14,1},{14,5},{15,2},{15,6},{16,3},{16,7},
	{'M',4},
		{3,4},{3,8},{5,3},{5,7},
			{8,1},{8,5},{10,3},{10,7},{12,2},{12,6},
		{14,1},{14,5},{15,2},{15,6},{16,3},{16,7},
{'F',14},
	{'M',1},
		{1,5},{3,1},{5,5},{6,1},
			{8,5},{10,1},{12,5},
		{13,1},{14,5},{15,1},
	{'M',2},
		{1,6},{3,2},{5,6},{6,2},
			{8,6},{10,2},{12,6},
		{13,2},{14,6},{15,2},
	{'M',3},
		{1,8},{3,4},{5,8},{6,4},
			{8,7},{10,3},{12,7},
		{13,3},{14,7},{15,3},
	{'M',4},
		{1,6},{3,2},{5,6},{6,2},
			{8,5},{10,1},{12,5},
		{13,1},{14,5},{15,1},
{'F',15},
	{'M',1},
		{1,5},{3,1},{5,5},{6,1},
			{8,5},{10,1},{12,5},
		{13,1},{14,5},{15,1},
	{'M',2},
		{1,6},{3,2},{5,6},{6,2},
			{8,6},{10,2},{12,6},
		{13,2},{14,6},{15,2},
	{'M',3},
		{1,8},{3,4},{5,8},{6,4},
			{8,8},{10,4},{12,8},
		{13,4},{14,8},{15,4},
	{'M',4},
		{1,8},{3,4},{5,8},{6,4},
			{8,8},{10,4},{12,8},
		{13,4},{14,8},{15,4},
}))

table.insert(tracks,generateTrack(
	1,
	"Tiny Little Adiantum",
	"ZUN arr.Shibayan",
	452,
	90,
	0,
{
{'F',0},
	{'M',1},
		{1,4}, {3,5},{3,7},
		{5,4},	{6,5},{6,7},
		{9,4}, {11,5},{11,7},
		{13,4},	{14,5},{14,7},
	{'M',2},
		{1,3}, {3,5},{3,8},
		{5,3},	{6,5},{6,8},
		{9,3}, {11,6},{11,8},
		{13,3},	{14,6},{14,8},
	{'M',3},
		{1,3}, {3,7},{3,8},
		{5,3},	{6,7},{6,8},
		{9,3}, {11,7},{11,8},
		{13,3},	{14,6},{14,7},
	{'M',4},
		{1,2}, {3,5},{3,6},
		{5,2}, {6,5},{6,6},
		{9,1}, {11,5},{11,8},
		{13,1}, {14,5},{14,8},
{'F',1},
	{'M',1},
		{1,4}, {3,5},{3,7},
		{5,4},	{6,5},{6,7},
		{9,4}, {11,5},{11,7},
		{13,4},	{14,5},{14,7},
	{'M',2},
		{1,3}, {3,5},{3,8},
		{5,3},	{6,5},{6,8},
		{9,3}, {11,6},{11,8},
		{13,3},	{14,6},{14,8},
	{'M',3},
		{1,3}, {3,7},{3,8},
		{5,3},	{6,7},{6,8},
		{9,3}, {11,7},{11,8},
		{13,3},	{14,6},{14,7},
	{'M',4},
		{1,2}, {3,5},{3,6},
		{5,2}, {6,5},{6,6},
		{9,1},{9,5},{9,7}, {12,1},
		{13,5},{13,7}, {14,1},
			{15,5},{15,6}, {16,1},
{'F',2},
	{'M',1},
		{1,4},{1,5}, {4,8},{5,1},
		{7,8},{8,1},{9,8}, {11,1},{12,8},
			{14,1},{15,8},{16,1},
	{'M',2},
		{1,8}, {3,1},{4,8},
		{5,1},{6,5},{7,4},{8,5},
		{9,6}, {12,3},
		{13,5},{14,3},{15,4},{16,5},
	{'M',3},
		{1,6}, {4,3},
		{5,5},{6,3},{7,4},{8,5},
		{9,6}, {12,3},
		{13,5},{14,3},{15,4},{16,5},
	{'M',4},
		{1,6}, {3,4},{4,6},
			{6,7},{8,8},{10,7},{12,6},
		{14,4},{15,5},
{'F',3},
	{'M',1},
		{4,1},{5,5},{6,4}, {8,5},
		{9,4}, {11,5},{12,4},
		{13,5},{14,4},{15,5},{16,4},
	{'M',2},
		{2,5}, {4,4},
		{5,5}, {7,4},{8,8},
		{9,4}, {12,3},
		{13,5},{14,3},{15,4},{16,5},
	{'M',3},
		{1,6}, {4,3},
		{5,5},{6,3},{7,4},{8,5},
		{9,6}, {12,1},
		{13,2},{14,3}, {16,4},
	{'M',4},
		{1,7}, {3,4},{4,8},
			{6,1}, {8,5}, {12,4},
		{13,5},{14,6}, {16,3},
{'F',4},
	{'M',1},
		{4,6},
		{5,3}, {7,6},{8,3},
		{9,6}, {11,3},{12,6},
			{14,3}, {16,5},
	{'M',2},
		{2,4}, {4,5},
		{6,4}, {8,5},
		{9,6}, {12,6},
		{13,5},{14,4},{15,5},
	{'M',3},
		{1,3}, {4,5},
		{12,3},
		{13,6},{14,5},{15,4},
	{'M',4},
		{1,5}, {3,4},{4,5}, {6,4},
		{8,6},{10,5},{12,4},{14,3},
{'F',5},
	{'M',1},
		{8,4},
		{9,5}, {11,4},{12,5},
		{14,4}, {16,3},
	{'M',2},
		{1,4}, {4,5},
		{13,4},{15,3},
	{'M',3},
		{1,4}, {4,5},
		{13,4},{15,3},
	{'M',4},
		{1,5}, {3,4},{4,5}, {6,6},
		{8,7},{10,6},{12,5},{14,4},
{'F',6},
	{'M',1},
		{5,4},{9,8},{13,1},
	{'M',2},
		{1,3}, {4,6},
		{13,5},{15,1},
	{'M',3},
		{1,5}, {4,4},
		{16,4},
	{'M',4},
		{1,5}, {3,4},{4,5}, {6,6},
		{8,7},{10,6},{12,5},{14,4},
		{16,1},
{'F',7},
	{'M',1},
		{1,2}, {4,5},
		{12,2},{13,3},{14,4},{15,5},{16,7},
	{'M',2},
		{1,6},
		{9,4},{13,7},
	{'M',3},
		{1,2}, {4,5},
		{16,2},
	{'M',4},
		{1,7}, {3,2},{4,4}, {6,5},
		{8,6},{10,5},{12,4},{14,3},
		{16,4},
{'F',8},
	{'M',1},
		{2,6},{3,5},
		{13,1},{15,3},{16,4},
	{'M',2},
		{1,6}, {3,5},{4,4}, {6,5},
		{8,6},{10,5},{12,4},{14,3},
		{16,4},
	{'M',3},
		{1,5}, {3,6},{4,7},
		{13,5},{15,4},
	{'M',4},
		{1,5}, {3,4},{4,5}, {6,6},
		{8,7},{10,6},{12,5},{14,4},
		{16,1},
{'F',9},
	{'M',1},
		{1,4},{4,5}, {12,1},
		{13,3},{14,4},{15,5},{16,7},
	{'M',2},
		{1,6},
		{9,4},{13,6},
	{'M',3},
		{1,3}, {3,4},{4,5}, {12,4},
		{13,5}, {15,3},{16,4},
	{'M',4},
		{1,6}, {3,5},{4,4}, {6,6},
		{8,8},{10,6},{12,4},{14,2},
{'F',10},
	{'M',1},
		{4,6},
		{5,3}, {8,6},
		{9,3}, {11,6},{12,3},
			{14,6}, {16,5},
	{'M',2},
		{2,4}, {4,5},
		{6,4}, {8,5},
		{9,6}, {12,6},
		{13,4},{14,5},{15,4},
	{'M',3},
		{1,3}, {4,5}, {12,4},
		{13,5},{14,3},{15,4},
	{'M',4},
		{1,5}, {3,4},{4,5}, {6,4},
		{8,6},{10,5},{12,4},{14,3},
{'F',11},
	{'M',1},
		{4,8},
		{5,1}, {7,8},
		{9,1}, {11,8},{12,1},
		{13,8},{14,4}, {16,6},
	{'M',2},
		{3,4},{4,6}, {6,4}, {8,5},
		{9,6}, {12,6},
		{13,5},{14,4},{15,5},
	{'M',3},
		{1,3}, {4,5}, {12,4},
		{13,5},{14,3},{15,4},
	{'M',4},
		{1,5}, {3,4},{4,5}, {6,6},
		{8,7},{10,6},{12,5},{14,4},
{'F',12},
	{'M',1},
		{4,4},
		{5,8}, {7,1},{8,8},
		{10,1},{12,8},{14,4},{16,6},
	{'M',2},
		{3,4},{4,6}, {6,4},{8,5},
		{9,6}, {12,6},
		{13,5},{14,3},{15,4},{16,5},
	{'M',3},
		{1,6}, {4,3},
		{5,5},{6,3},{7,4},{8,5},
		{9,6}, {12,3},
		{13,5},{14,3},{15,4},
	{'M',4},
		{1,5}, {3,4},{4,5}, {6,6},
		{8,7}, {10,8}, {12,5},
		{13,4},{15,3},
{'F',13},
	{'M',1},
		{4,1},
		{5,5},{6,4},{7,5},{8,4},
		{9,5}, {11,4},{12,5}, {14,8},
		{16,4},
	{'M',2},
		{2,5},{4,3},
		{5,5},{6,3}, {8,5},
		{9,6}, {12,3},
		{14,4},{16,5},
	{'M',3},
		{1,6}, {3,5},{4,4},
		{6,2},{8,4},{10,6},
		{11,4},
		{14,6},{15,5},{16,4},
	{'M',4},
		{1,5}, {3,3},{4,4}, {6,5},
		{8,6},{10,5},{12,4},{14,3},{16,6},
{'F',14},
	{'M',1},
		{1,5},{1,1}, {3,5},{3,7},
		{5,4},	{6,5},{6,7},
		{9,4}, {11,5},{11,7},
		{13,4},	{14,5},{14,7},
	{'M',2},
		{1,3}, {3,5},{3,8},
		{5,3},	{6,5},{6,8},
		{9,3}, {11,6},{11,8},
		{13,3},	{14,6},{14,8},
	{'M',3},
		{1,3}, {3,7},{3,8},
		{5,3},	{6,7},{6,8},
		{9,3}, {11,7},{11,8},
		{13,3},	{14,6},{14,7},
	{'M',4},
		{1,2}, {3,5},{3,6},
		{5,2}, {6,5},{6,6},
		{9,1}, {11,5},{11,8},
		{13,1}, {14,5},{14,8},
{'F',15},
	{'M',1},
		{1,4}, {3,7},
		{5,4},	{6,7},
		{9,4}, {11,7},
		{13,4},	{14,7},
	{'M',2},
		{1,3}, {3,8},
		{5,3},	{6,8},
		{9,3}, {11,8},
		{13,3},	{14,8},
	{'M',3},
		{1,3}, {3,6},
		{5,3},	{6,6},
		{9,3}, {11,6},
		{13,3},	{14,5},
	{'M',4},
		{1,4}, {3,5},
		{5,4}, {6,5},
		{9,4}, {11,5},
		{13,4}, {14,5}
}))

table.insert(tracks,generateTrack(
	2,
	"Le Petit Negre",
	"Claude Debussy",
	456,
	140,
	0,
{
{'F',0},
	{'M',1},
		{1,4},{2,5}, {4,4},
		{5,5},{7,4},
		{9,3},{10,6}, {12,3},
		{13,6},{14,3},
	{'M',2},
		{1,5},{2,7}, {4,5},{5,7},
			{7,5},{8,7},{9,5},
		{1,1},{1,2},{3,2},{3,3},
			{5,3},{5,4},{7,2},{7,3},
		{9,1},{9,2},{11,3},{11,4},
			{13,2},{13,3},{15,1},{15,2},
	{'M',3},
		{1,2},{2,4}, {4,2},{5,1},{7,2},
		{1,7},{1,8},{3,6},{3,7},
			{5,5},{5,6},{7,4},{7,5},
		{9,6},{10,8}, {12,6},{13,5},
		{9,4},{9,5},{11,3},{11,4},
			{13,2},{13,3},{15,1},{15,2},
	{'M',4},
		{1,2},{2,4}, {4,4},{5,2},
			{7,2},{8,4},{9,2},
		{1,7},{1,8},{3,6},{3,7},
			{5,5},{5,6},{7,6},{7,7},
		{9,8},{11,1},{13,8},{15,1},
{'F',1},
	{'M',1},
		{1,4},{2,5}, {4,4},{5,5}, {7,4},
		{1,1},{3,8},{5,1},{7,8},
		{9,3},{10,6}, {12,3},{13,6}, {15,3},
		{9,1},{11,8},{13,1},{15,8},
	{'M',2},
		{1,2},{2,7}, {4,2},{5,7},
			{7,2},{8,7},{9,2},
		{1,1},{3,8},{5,1},{7,8},
			{9,1},{11,8},{13,1},{15,8},
	{'M',3},
		{1,1},{2,2}, {4,4},
		{5,5},{7,7},
		{9,1},{10,2}, {12,4},
		{13,5}, {15,6},{16,8},
	{'M',4},
		{1,1},{2,3}, {4,4},
			{5,5}, {7,6},{8,7},
		{7,2},{7,4},
		{9,1},{9,3},{9,5},{9,8},
		{15,4},
{'F',2},
	{'M',1},
		{1,6},{7,5},
		{3,4},{3,8},
		{9,4},{15,3},
		{11,2},{11,6},
	{'M',2},
		{1,5},{5,4},{9,3},
		{3,1},{3,8},{7,1},{7,8},
			{11,1},{11,8},
		{15,1},
	{'M',3},
		{1,2},{3,3},{5,4},{7,5},
		{9,6},{11,7},{13,8},{15,7},
	{'M',4},
		{1,6},
		{3,1},{3,8},{7,1},{7,8},
			{11,1},{11,8},
		{15,4},
{'F',3},
	{'M',1},
		{1,6},{7,5},
		{3,4},{3,8},
		{9,4},{15,3},
		{11,2},{11,6},
	{'M',2},
		{1,5},{5,4},{9,3},
		{3,1},{3,8},{7,1},{7,8},
			{11,1},{11,8},
		{15,1},{15,5},
	{'M',3},
		{1,2},{1,6},{3,3},{3,7},
			{5,4},{5,8},{7,1},{7,5},
		{9,2},{9,6},{11,3},{11,7},
			{13,4},{13,8},{15,2},{15,6},
	{'M',4},
		{1,4},{1,8},{3,2},{3,6},
		{5,4},{5,8},{7,3},{7,7},
		{9,4},{9,8},{11,3},{11,7},
		{13,4},{13,8},
		{15,5},
{'F',4},
	{'M',1},
		{1,6},{2,8}, {4,6},{5,8}, {7,6},
		{1,4},{5,3},
		{9,5},{10,7}, {12,5},{13,7}, {15,5},
		{9,2},{13,1},
	{'M',2},
		{1,2},{2,4}, {4,2},{5,4},
			{7,2},{8,4},{9,2},
		{1,5},{1,6},{3,6},{3,7},
			{5,7},{5,8},{7,6},{7,7},
		{9,5},{9,6},{11,7},{11,8},
			{13,6},{13,7},{15,5},{15,6},
	{'M',3},
		{1,6},{2,8}, {4,6},{5,5},{7,6},
		{1,4},{1,5},{3,3},{3,4},
			{5,2},{5,3},{7,1},{7,2},
		{9,2},{10,4}, {12,2},{13,1},
		{9,7},{9,8},{11,6},{11,7},
			{13,5},{13,6},{15,4},{15,5},
	{'M',4},
		{1,5},{2,7}, {4,5},{5,7},
			{7,5},{8,7},{9,5},
		{1,3},{1,4},{3,2},{3,3},
			{5,1},{5,2},{7,2},{7,3},
		{9,8},{11,1},{13,8},{15,1},
{'F',5},
	{'M',1},
		{1,4},{2,5}, {4,4},{5,5}, {7,4},
		{1,1},{3,8},{5,1},{7,8},
		{9,3},{10,6}, {12,3},{13,6}, {15,3},
		{9,1},{11,8},{13,1},{15,8},
	{'M',2},
		{1,2},{2,7}, {4,2},{5,7},
			{7,2},{8,7},{9,2},
		{1,1},{3,8},{5,1},{7,8},
			{9,1},{11,8},{13,1},{15,8},
	{'M',3},
		{1,1},{2,2}, {4,4},
		{5,5},{7,7},
		{9,1},{10,2}, {12,4},
		{13,5}, {15,6},{16,8},
	{'M',4},
		{1,1},{2,3}, {4,4},
			{5,5}, {7,6},{8,7},
		{7,2},{7,4},
		{9,1},{9,3},{9,5},{9,8},
		{15,4},
{'F',6},
	{'M',1},
		{1,6},{7,5},
		{3,4},{3,8},
		{9,4},{15,3},
		{11,2},{11,6},
	{'M',2},
		{1,5},{5,4},{9,3},
		{3,1},{3,8},{7,1},{7,8},
			{11,1},{11,8},
		{15,1},
	{'M',3},
		{1,2},{3,3},{5,4},{7,5},
		{9,6},{11,7},{13,8},{15,7},
	{'M',4},
		{1,6},
		{3,1},{3,8},{7,1},{7,8},
			{11,1},{11,8},
		{15,4},
{'F',7},
	{'M',1},
		{1,6},{7,5},
		{3,4},{3,8},
		{9,4},{15,3},
		{11,2},{11,6},
	{'M',2},
		{1,5},{5,4},{9,3},
		{3,1},{3,8},{7,1},{7,8},
			{11,1},{11,8},
		{15,1},{15,5},
	{'M',3},
		{1,2},{1,6},{3,3},{3,7},
			{5,4},{5,8},{7,1},{7,5},
		{9,2},{9,6},{11,3},{11,7},
			{13,4},{13,8},{15,2},{15,6},
	{'M',4},
		{1,4},{1,8},{3,2},{3,6},
		{5,4},{5,8},{7,3},{7,7},
		{9,4},{9,8},{11,3},{11,7},
		{13,4},{13,8},
		{15,5},
{'F',8},
	{'M',1},
		{1,2},{2,4}, {4,2},{5,4}, {7,2},
		{1,8},{5,7},
		{9,1},{10,3}, {12,1},{13,3}, {15,1},
		{9,6},{13,5},
	{'M',2},
		{1,5},{2,7}, {4,5},{5,7},
			{7,5},{8,7},{9,5},
		{1,1},{1,2},{3,2},{3,3},
			{5,3},{5,4},{7,2},{7,3},
		{9,1},{9,2},{11,3},{11,4},
			{13,2},{13,3},{15,1},{15,2},
	{'M',3},
		{1,2},{2,4}, {4,2},{5,1},{7,2},
		{1,7},{1,8},{3,6},{3,7},
			{5,5},{5,6},{7,4},{7,5},
		{9,6},{10,8}, {12,6},{13,5},
		{9,4},{9,5},{11,3},{11,4},
			{13,2},{13,3},{15,1},{15,2},
	{'M',4},
		{1,2},{2,4}, {4,4},{5,2},
			{7,2},{8,4},{9,2},
		{1,7},{1,8},{3,6},{3,7},
			{5,5},{5,6},{7,6},{7,7},
		{9,8},{11,1},{13,8},{15,1},
{'F',9},
	{'M',1},
		{1,4},{2,5}, {4,4},{5,5}, {7,4},
		{1,1},{3,8},{5,1},{7,8},
		{9,3},{10,6}, {12,3},{13,6}, {15,3},
		{9,1},{11,8},{13,1},{15,8},
	{'M',2},
		{1,2},{2,7}, {4,2},{5,7},
			{7,2},{8,7},{9,2},
		{1,1},{3,8},{5,1},{7,8},
			{9,1},{11,8},{13,1},{15,8},
	{'M',3},
		{1,1},{2,2}, {4,4},
		{5,5},{7,7},
		{9,1},{10,2}, {12,4},
		{13,5}, {15,6},{16,8},
	{'M',4},
		{1,1},{2,3}, {4,4},
			{5,5}, {7,6},{8,7},
		{7,2},{7,4},
		{9,1},{9,3},{9,5},{9,8},
		{13,1},{13,3},{13,5},{13,8},
}))

--frameStart(0,15,true)
