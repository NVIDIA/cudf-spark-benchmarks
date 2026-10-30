
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND 
        o.o_orderdate < DATE '1997-12-31'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name
),
HighValueOrders AS (
    SELECT 
        o.o_custkey,
        COUNT(l.l_orderkey) AS total_lineitems,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        l.l_returnflag = 'N' 
    GROUP BY 
        o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
)
SELECT 
    r.n_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(s.total_supply_cost) AS avg_supply_cost,
    SUM(h.net_revenue) AS total_revenue
FROM 
    nation r
LEFT JOIN 
    customer c ON r.n_nationkey = c.c_nationkey
LEFT JOIN 
    SupplierStats s ON s.parts_supplied > 10
LEFT JOIN 
    HighValueOrders h ON c.c_custkey = h.o_custkey
WHERE 
    r.n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name LIKE '%East%')
GROUP BY 
    r.n_name
HAVING 
    AVG(s.total_supply_cost) IS NOT NULL
ORDER BY 
    customer_count DESC, 
    total_revenue DESC
LIMIT 5;
