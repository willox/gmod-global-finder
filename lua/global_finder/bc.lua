-- Some code borrowed from jit/bc.lua
-- Many functions in use here are undocumented

local bcnames = "ISLT  ISGE  ISLE  ISGT  ISEQV ISNEV ISEQS ISNES ISEQN ISNEN ISEQP ISNEP ISTC  ISFC  IST   ISF   MOV   NOT   UNM   LEN   ADDVN SUBVN MULVN DIVVN MODVN ADDNV SUBNV MULNV DIVNV MODNV ADDVV SUBVV MULVV DIVVV MODVV POW   CAT   KSTR  KCDATAKSHORTKNUM  KPRI  KNIL  UGET  USETV USETS USETN USETP UCLO  FNEW  TNEW  TDUP  GGET  GSET  TGETV TGETS TGETB TSETV TSETS TSETB TSETM CALLM CALL  CALLMTCALLT ITERC ITERN VARG  ISNEXTRETM  RET   RET0  RET1  FORI  JFORI FORL  IFORL JFORL ITERL IITERLJITERLLOOP  ILOOP JLOOP JMP   FUNCF IFUNCFJFUNCFFUNCV IFUNCVJFUNCVFUNCC FUNCCW"
-- These bcnames could be incorrect depending on what Garry changes with LuaJIT. But it's unlikely and GSET works correctly at least
-- They are exported from a file generated when compiling LuaJIT. :(

local function GetOperatorName(ins)
	local oidx = 6 * bit.band(ins, 0xff)

	return string.Trim(string.sub(bcnames, oidx + 1, oidx + 6))
end

local function IterateChildren(func)
	local info = jit.util.funcinfo(func)

	if not info.children then
		return (function()
			return
		end)
	end

	local n = 0
	local ret = {}

	return function()
		n = n - 1

		local k = jit.util.funck(func, n)

		if not k then return end

		return n, k
	end
end

local function IterateBytecode(func)
	local pc = 0
	local ret = {}

	return function()
		pc = pc + 1

		local ins, op = jit.util.funcbc(func, pc)

		if not ins then return end

		local oidx = 6 * bit.band(ins, 0xff)

		ret['opcode'] = op
		ret['ins'] = ins
		ret['op'] = GetOperatorName(ins)

		return pc, ret
	end
end

return {
	GetOperatorName = GetOperatorNamem,
	IterateChildren = IterateChildren,
	IterateBytecode = IterateBytecode
}