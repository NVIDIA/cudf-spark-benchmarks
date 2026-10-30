SELECT
    SUPP.s_name,
    NAT.n_name,
    SUM(PS.ps_availqty) AS total_available_qty,
    AVG(PS.ps_supplycost) AS average_supply_cost
FROM
    supplier SUPP
JOIN
    nation NAT ON SUPP.s_nationkey = NAT.n_nationkey
JOIN
    partsupp PS ON SUPP.s_suppkey = PS.ps_suppkey
GROUP BY
    SUPP.s_name,
    NAT.n_name
ORDER BY
    total_available_qty DESC
LIMIT 10;
