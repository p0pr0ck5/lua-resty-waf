local rs_35000 = {}

local _rules = {
	{
		id = "35001",
		vars = {
			{
				type = "HEADERS",
				opts = { { specific = "User-Agent" } },
				pattern = [=[(?:(?:grabber|cgichk|bsqlbf|mozilla/4.0 (compatible)|sqlmap|mozilla/4.0 (compatible; msie 6.0; win32)|mozilla/5.0 sf//|nessus|arachni|metis|sql power injector|bilbo|absinthe|black widow|n-stealth|brutus|webtrends security analyzer|netsparker|python-httplib2|jaascois|pmafind|.nasl|nsauditor|paros|dirbuster|pangolin|nmap nse|sqlninja|nikto|webinspect|blackwidow|grendel-scan|havij|w3af|hydra|masscan/1.0))]=],
				operator = "REGEX",
			}
		},
		action = "LOG",
		description = "User-Agent string indicates an automated program scanned the site"
	},
	{
		id = "35002",
		vars = {
			{
				type = "HEADERS",
				opts = { { specific = "User-Agent" } },
				pattern = [=[(?:(?:c(?:o(?:n(?:t(?:entsmartz|actbot(?:/)?)|cealed defense|veracrawler)|mpatible(?: ;(?: msie|\.)|-)|py(?:rightcheck|guard)|re-project/1.0)|h(?:ina(?: local browse 2\.|claw)|e(?:rrypicker|esebot))|rescent internet toolpak)|w(?:e(?:b(?: (?:downloader|by mail)|(?:(?:altb|ro)o|bandi)t|emailextract?|vulnscan|mole)|lls search ii|p Search 00)|i(?:ndows(?:-update-agent)|se(?:nut)?bot)|ordpress(?: hash grabber|\/4\.01)|3mir)|m(?:o(?:r(?:feus fucking scanner|zilla)|zilla\/3\.mozilla\/2\.01$|siac 1.)|i(?:crosoft (?:internet explorer\/5\.0$|url control)|ssigua)|ailto:craftbot\@yahoo\.com|urzillo compatible)|p(?:ro(?:gram shareware 1\.0\.|duction bot|webwalker)|a(?:nscient\.com|ckrat)|oe-component-client|s(?:ycheclone|urf)|leasecrawl\/1\.|cbrowser|e 1\.4|mafind)|e(?:mail(?:(?:collec|harves|magne)t|(?: extracto|reape)r|(siphon|spider)|siphon|wolf)|(?:collecto|irgrabbe)r|ducate search vxb|xtractorpro|o browse)|t(?:(?: ?h ?a ?t ?' ?s g ?o ?t ?t ?a ? h ?u ?r ?|his is an exploi|akeou)t|oata dragostea mea pentru diavola|ele(?:port pro|soft)|uring machine)|a(?:t(?:(?:omic_email_hunt|spid)er|tache|hens)|d(?:vanced email extractor|sarobot)|gdm79\@mail\.ru|miga-aweb\/3\.4|utoemailspider| href=)|^(?:(google|i?explorer?\.exe|(ms)?ie( [0-9.]+)?\ ?(compatible( browser)?)?)$|www\.weblogs\.com|(?:jakart|vi)a|microsoft url|user-Agent)|s(?:e(?:archbot admin@google.com|curity scan)|(?:tress tes|urveybo)t|\.t\.a\.l\.k\.e\.r\.|afexplorer tl|itesnagger|hai)|n(?:o(?:kia-waptoolkit.* googlebot.*googlebot| browser)|e(?:(?:wt activeX; win3|uralbot\/0\.)2|ssus)|ameofagent|ikto)|f(?:a(?:(?:ntombrows|stlwspid)er|xobot)|(?:ranklin locato|iddle)r|ull web bot|loodgate|oobar/)|i(?:n(?:ternet(?: (?:exploiter sux|ninja)|-exprorer)|dy library)|sc systems irc search 2\.1)|g(?:ameBoy, powered by nintendo|rub(?: crawler|-client)|ecko\/25)|(myie2|libwen-us|murzillo compatible|webaltbot|wisenutbot)|b(?:wh3_user_agent|utch__2\.1\.1|lack hole|ackdoor)|d(?:ig(?:imarc webreader|out4uagent)|ts agent)|(?:(script|sql) inject|$botname/$botvers)ion|(msie .+; .*windows xp|compatible \; msie)|h(?:l_ftien_spider|hjhj@yahoo|anzoweb)|(?:8484 boston projec|xmlrpc exploi)t|u(?:nder the rainbow 2\.|ser-agent:)|(sogou develop spider|sohu agent)|(?:(?:d|e)browse|demo bot)|zeus(?: .*webster pro)?|[a-z]surf[0-9][0-9]|v(?:adixbot|oideye)|larbin@unspecified|\bdatacha0s\b|kenjin spider|; widows|rsync|\\\r))]=],
			operator = "REGEX"
			}
		},
		action = "LOG",
		description = "Known malicious bot"
	}
}

function rs_35000.rules()
	return _rules
end

return rs_35000
