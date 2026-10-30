WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-10-01'
), TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(CASE WHEN ro.order_rank <= 10 THEN ro.o_totalprice ELSE 0 END) AS total_top_price
    FROM 
        nation n
    JOIN 
        RankedOrders ro ON n.n_nationkey = ro.c_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
), SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS parts_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    tn.n_name,
    tn.total_top_price,
    ss.s_name,
    ss.parts_count,
    ss.total_supply_cost
FROM 
    TopNations tn
JOIN 
    SupplierStats ss ON tn.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'United States')
ORDER BY 
    tn.total_top_price DESC, ss.total_supply_cost ASC
LIMIT 10;