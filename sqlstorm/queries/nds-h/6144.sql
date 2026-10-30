
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY 
        o.o_orderkey
),
TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        SUM(s.s_acctbal) > 100000
)
SELECT 
    r.r_name AS region_name,
    tn.n_name AS nation_name,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    SUM(ro.total_revenue) AS total_revenue,
    AVG(tn.total_account_balance) AS avg_account_balance
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    TopNations tn ON n.n_nationkey = tn.n_nationkey
LEFT JOIN 
    RankedOrders ro ON tn.n_nationkey = (SELECT n2.n_nationkey FROM nation n2 JOIN supplier s2 ON n2.n_nationkey = s2.s_nationkey WHERE s2.s_acctbal > 100000) 
GROUP BY 
    r.r_name, tn.n_name
ORDER BY 
    total_revenue DESC, total_orders DESC
LIMIT 10;
