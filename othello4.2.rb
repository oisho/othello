#! ruby -Ku

#CPU3、プレイヤー側がパスになると、空配列参照になってバグる

$board = Array.new(10).map{Array.new(10,3)}
#配列準備、番兵含め10*10
$dubBoard = Marshal.load(Marshal.dump($Board))
#AIが使う判断用に使うboardの複製

i = 1 #行
j = 1 #列
turn = 1 #1=黒　2=白を示す
passCount = 0 #パスが連続して二回続く、つまりお互いおけなくなるとゲーム終了判定
l = 0 #ひっくり返せる個数、AIが判定用に使う
ai = 0 #0:AIなし　1:AI黒　2:AI白

while i < 9
	for j in 1..8
		$board[i][j] = 0
	end
	i += 1
end #番兵以外に0を代入

$board[4][5] = 1
$board[5][4] = 1
$board[4][4] = 2
$board[5][5] = 2



#初期配置

#ボードを表示する関数
def showBoard()
	i = 0
	j = 0
	cell = Array.new(10).map{Array.new(10)}
	while i < 10
		for j in 0..9
			if $board[i][j] == 0
				cell[i][j] = "+ "
			elsif $board[i][j] == 1
				cell[i][j] = "● "
			elsif $board[i][j] == 2
				cell[i][j] = "○ "
			elsif $board[i][j] == 3
				cell[i][j] = "  "
			end
			cell[0][j] = j.to_s + " "
		end
		cell[i][0] = i.to_s + " "
		i += 1
	end
	cell[0][0],cell[0][9],cell[9][0] = "  ","  ","  "
	row = Array.new(10)
	i = 0
	while i < 10
		row[i] = row[i].to_s
		for j in 0..9
			a = cell[i][j].to_s
			row[i] = row[i] << a
		end
		puts row[i]
		i += 1
	end
end

#石を置けるか判定し、置けるようならdubBoardに置いた状態を返す
def checkCell(i,j,turn,flip)
	dx = 0 #8方向判定用関数
	dy = 0 #8方向判定用関数
	n = 0 #あるラインでひっくり返せる個数
	l = 0 #ひっくり返せる個数
	canPut = false
	if i > 8 || i < 1 || j > 8 || j < 0
#		puts "you can't put here"
		return canPut, l
	end
	$dubBoard = Marshal.load(Marshal.dump($board))
	if $dubBoard[i][j] != 0
		if flip == true
#			puts "you can't put here"
		end
		return canPut, l
	end
	for dy in [-1,0,1]
	for dx in [-1,0,1]
		n = 0
		x = dx
		y = dy
		if (x == 0 && y == 0)
			next
		end
		while $dubBoard[i+x][j+y] == 3-turn
			n += 1
			x += dx
			y += dy
		end
		if (n > 0 && $dubBoard[i+x][j+y] == turn)
			if flip == true
				$dubBoard[i][j] = turn #指定位置に石を置く
				for m in 1..n
					$dubBoard[i+m*dx][j+m*dy] = turn #ボードをひっくり返す
					l += 1 #ひっくり返せる個数を返す
				end
			else
				for m in 1..n
					l += 1 #ボードをひっくり返さないが、ひっくり返せる個数は返す
				end
			end
			canPut = true
		end
	end
	end
	if canPut == false
		if flip == true
#			puts "you can't put here"
		end
		return canPut, l
	end
	return canPut, l
end #flip trueなら指定位置に石が置けるか対応箇所を判定後反転させる。falseなら判定のみ

#最も大きくひっくり返せる座標を返す。しょぼいAI
def cpu(turn)
	ii =[] #おけるところの行座標を格納
	jj =[] #おけるところの列座標を格納
	ll =[] #ひっくり返せる個数を格納
	for i in 1..8
	for j in 1..8
		canPut, l = checkCell(i,j,turn,false)
		if l > 0
			ii.push(i)
			jj.push(j)
			ll.push(l)
		end
	end
	end
	ind = ll.index(ll.max)
	i = ii[ind]
	j = jj[ind]
	return i,j
end 

#評価関数　その1
def eval1(board,turn)
	score = 0
	for i in 2..7
	for j in 2..7
		if board[i][j] == turn
			score += 1
		end
	end
	end
	for i in [1,8]
	for j in 2..7
		if board[i][j] == turn
			score += 2
		end
	end
	end
	for i in 2..7
	for j in [1,8]
		if board[i][j] == turn
			score += 2
		end
	end
	end
	for i in [1,8]
	for j in [1,8]
		if board[i][j] == turn
			score += 14
		end
	end
	end
	return score
end

#ゲームセット時に呼び出される関数
def gameset()
	puts "gameset!"
	b = 0
	w = 0
	for i in 1..8
	for j in 1..8
		if $board[i][j] == 1
			b += 1
		elsif $board[i][j] == 2
			w += 1
		end
	end
	end
	puts "black:" + b.to_s + ", white:" + w.to_s
	if b == w
		puts "draw!!!"
	elsif b > w
		puts "black won!!!"
	else
		puts "white won!!!"
	end
end

#評価点が最も高いところに置くCPU
def cpu2(turn)
	ii =[] #おけるところの行座標を格納
	jj =[] #おけるところの列座標を格納
	scoreArray = [] #各候補の評価点を格納
	for i in 1..8
	for j in 1..8
		canPut,l = checkCell(i,j,turn,true)
		if canPut
			ii.push(i)
			jj.push(j)
			scoreArray.push(eval1($dubBoard,turn))
		end
	end
	end
#	p ii
#	p jj
#	p scoreArray
	ind = scoreArray.index(scoreArray.max)
	i = ii[ind]
	j = jj[ind]
	return i,j
end

#相手が評価点を最大にしてくると仮定して、２ターン後に評価点を最大化する位置に置くCPU
def cpu3(turn)
	defBoard = Marshal.load(Marshal.dump($board)) #本来のボードを一時的に複製、保存
	ii =[] #おけるところの行座標を格納
	jj =[] #おけるところの列座標を格納
	scoreArray = [] #各候補の評価点を格納
	turnOp = 3 - turn #相手のターン
	for i in 1..8
	for j in 1..8
#		cP = false #プレイヤー側がパス判定になるときに使う
		$board = Marshal.load(Marshal.dump(defBoard)) #ボードを読み直す	
		canPut,l = checkCell(i,j,turn,true) #置ける場所を探す
		if canPut #置ける候補が見つかったとき、そこに置いたときに相手が評価関数を最大化する行動を考える
			$board = Marshal.load(Marshal.dump($dubBoard)) #一時的に石を置いたボードを用意
			#p "a" #テスト
			#showBoard() #テスト
			scoreArray2 = [] #相手の各候補の評価点を格納
			iii = [] #相手の置けるところの行座標を格納
			jjj = [] #相手の置けるところの列座標を格納
			for i2 in 1..8
			for j2 in 1..8
				canPut,l = checkCell(i2,j2,turnOp,true)
				if canPut
					cP = true
					#p "canput" #テスト
					#p canPut #テスト
					iii.push(i2)
					jjj.push(j2)
					scoreArray2.push(eval1($dubBoard,turnOp)) #相手の各候補の評価関数を算出				
				end
			end
			end
			if cP == false
				scoreArray.push(eval1($board,turn)) 
				next
			end
			ind = scoreArray2.index(scoreArray2.max)
			i2 = iii[ind]
			j2 = jjj[ind]
			sO = scoreArray2[ind] #相手がこちらに対応して置く最高評価点
			i2,j2 = cpu2(turnOp)
			#p [i2,j2] #テスト
			canPut,l = checkCell(i2,j2,turnOp,true)
			$board = Marshal.load(Marshal.dump($dubBoard)) #相手が評価点を最大化できる場所においたボードを用意
			#p "b" #テスト
			#showBoard() #テスト
			ii.push(i)
			jj.push(j)
			sI = eval1($board,turn) #その状態でのこちらの評価点を算出
			#puts sO #テスト
			#puts sI #テスト
			scoreArray.push(sI-sO) #双方の評価点の差を評価点とする
		end
	end
	end
	#p ii #テスト
	#p jj #テスト
	#p scoreArray #テスト
	ind = scoreArray.index(scoreArray.max) #評価点最大のものを算出
	i3 = ii[ind]
	j3 = jj[ind]
	$board = Marshal.load(Marshal.dump(defBoard)) #ボードを読み直す		
	return i3,j3
end	


#program begin
#モードセレクト

puts "select the game mode"
puts "1: vs CPU"
puts "2: vs Player"

while 1
	mode = STDIN.gets.to_i
	if mode == 2
		ai = 0
		break
	elsif mode == 1
		puts "choose your color"
		puts "1: black"
		puts "2: white" 
		while 1
			mode = STDIN.gets.to_i
			if mode == 1
				ai = 2
				break
			elsif mode == 2
				ai = 1
				break
			else
				puts "input correct format"
			end
		end
		break
	else
	puts "input correct format"
	end
end

#実際のプレイ
while true
	showBoard()
	for i in 1..8
	for j in 1..8
		canPut,l = checkCell(i,j,turn,false)
		if canPut
			break
		end
	end
	if canPut
		break
	end
	end

	if canPut == false #もし片方がおけなければもう片方もそうか判定してゲームセットかパスか決める
		passCount = 1
		turn = 3 - turn
		for i in 1..8
		for j in 1..8
			canPut,l = checkCell(i,j,turn,false)
			if canPut
				break
			end
		end
		if canPut
			break
		end
		end
		if canPut == false
			gameset()
			#p eval1($board,turn)
			#p eval1($board,3-turn)
			break
		end
		turn = 3 - turn	
	end

	if (canPut == true && passCount == 1)
		if turn == 1
			tColor = "black"
		else
			tColor = "white"
		end
		puts tColor + "'s turn is passed"
		turn = 3 - turn
	end

	#ゲームが継続しプレイヤーかCPUのどちらかが置く処理
	if passCount == 0
		if turn == 1
			tColor = "black"
		else
			tColor = "white"
		end
		puts tColor + "'s turn"

		if ai == turn
			i,j = cpu3(turn)
		else
			k = STDIN.gets	
			a = k.split(",")
			i = a[0].to_i
			j = a[1].to_i
		end

		canPut,l = checkCell(i,j,turn,true)
		if canPut == true
			$board = Marshal.load(Marshal.dump($dubBoard))
		else
			puts "you can't put here"
		end
		if canPut
			turn = 3 - turn
		end
	end

	passCount = 0
	l = 0
end



