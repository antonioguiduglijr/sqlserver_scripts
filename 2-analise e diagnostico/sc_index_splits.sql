--https://www.fabriciolima.net/blog/2011/08/11/como-monitorar-o-page-split-de-um-indice/

---index split
select   allocUnitName,COUNT(*)
from    ::fn_dblog(null, null)
where Operation = 'LOP_DELETE_SPLIT'
group by allocUnitName
order by COUNT(*) desc
