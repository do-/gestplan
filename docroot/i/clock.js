function twoDigits (n) {
   if (n > 9) return n;
   return '0' + n;
}

function StartClock() {
   clockID = setTimeout("UpdateClock ()", 0);
}

function KillClock() {
	if (!clockID) return;
	clearTimeout(clockID);
	clockID  = 0;
}

function UpdateClock() {

   if (clockID) {
      clearTimeout (clockID);
      clockID = 0;
   }

   var tDate = new Date ();
   
   try {
	   document.getElementById ('clock_hours').innerText = twoDigits (tDate.getHours ());
	   document.getElementById ('clock_minutes').innerText = twoDigits (tDate.getMinutes ());
	   document.getElementById ('clock_separator').innerText = ':';
   } catch (e) {}

   clockID = setTimeout("UpdateClock ()", 10000);
   
}