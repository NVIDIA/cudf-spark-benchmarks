WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
RankedOrders AS (
    SELECT 
        od.o_orderkey,
        od.o_custkey,
        od.total_revenue,
        RANK() OVER (PARTITION BY od.o_custkey ORDER BY od.total_revenue DESC) AS revenue_rank
    FROM 
        OrderDetails od
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(ss.total_cost, 0) AS supplier_total_cost,
    COALESCE(oo.total_revenue, 0) AS customer_total_revenue,
    CASE WHEN ss.part_count > 5 THEN 'High' ELSE 'Low' END AS supplier_part_category
FROM 
    part p
LEFT JOIN 
    SupplierSummary ss ON p.p_partkey = ss.s_suppkey
LEFT JOIN 
    RankedOrders oo ON oo.o_custkey = (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA') 
        LIMIT 1
    )
WHERE 
    p.p_size < 20 
    AND p.p_retailprice BETWEEN 10.00 AND 100.00
ORDER BY 
    supplier_total_cost DESC, customer_total_revenue ASC;