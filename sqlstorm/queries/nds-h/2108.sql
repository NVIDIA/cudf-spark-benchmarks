WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), 
MaxCost AS (
    SELECT 
        MAX(total_cost) AS max_cost
    FROM 
        SupplierStats
), 
AvgPrice AS (
    SELECT 
        AVG(o.o_totalprice) AS avg_price
    FROM 
        RankedOrders o
)

SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    COALESCE(SUM(ps.ps_availqty), 0) AS total_available_quantity,
    COALESCE(MAX(ss.total_cost), 0) AS max_supplier_cost,
    COALESCE(AVG(o.o_totalprice), 0) AS average_order_price,
    p.p_name AS part_name,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 0 THEN 'Order Exists'
        ELSE 'No Orders'
    END AS order_status
FROM 
    nation n
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus = 'O'
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierStats ss ON ps.ps_suppkey = ss.s_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'Asia')
GROUP BY 
    n.n_name, p.p_name
HAVING 
    MAX(ss.total_cost) > (SELECT MAX(max_cost) FROM MaxCost)
    AND AVG(o.o_totalprice) > (SELECT AVG(avg_price) FROM AvgPrice)
ORDER BY 
    customer_count DESC;