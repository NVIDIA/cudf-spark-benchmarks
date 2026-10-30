WITH SupplierPartCounts AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrderCounts AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        c.c_custkey
),
LineItemRevenue AS (
    SELECT 
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        l.l_suppkey
)
SELECT 
    s.s_name AS supplier_name,
    s.s_address AS supplier_address,
    COALESCE(sp.part_count, 0) AS number_of_parts,
    COALESCE(co.order_count, 0) AS number_of_orders,
    COALESCE(lir.total_revenue, 0.00) AS total_revenue 
FROM 
    supplier s
LEFT JOIN 
    SupplierPartCounts sp ON s.s_suppkey = sp.s_suppkey
LEFT JOIN 
    CustomerOrderCounts co ON s.s_nationkey = co.c_custkey 
LEFT JOIN 
    LineItemRevenue lir ON s.s_suppkey = lir.l_suppkey
WHERE 
    s.s_acctbal > 1000.00
ORDER BY 
    total_revenue DESC, 
    number_of_orders DESC, 
    number_of_parts DESC
LIMIT 10;