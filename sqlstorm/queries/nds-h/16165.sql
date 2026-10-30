SELECT SUP.s_name, SUM(PS.ps_supplycost * PS.ps_availqty) AS total_cost
FROM supplier SUP
JOIN partsupp PS ON SUP.s_suppkey = PS.ps_suppkey
GROUP BY SUP.s_name
ORDER BY total_cost DESC
LIMIT 10;
