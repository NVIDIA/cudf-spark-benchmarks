WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(li.l_extendedprice * (1 - li.l_discount)) > 10000
),
AvgCustomerOrderValue AS (
    SELECT 
        c.c_custkey,
        AVG(ho.total_order_value) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        HighValueOrders ho ON c.c_custkey = ho.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        AVG(ho.total_order_value) IS NOT NULL
)
SELECT 
    p.p_name,
    SUM(ps.ps_availqty) AS total_available,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    CASE 
        WHEN SUM(ps.ps_availqty) > 0 THEN 'Available'
        ELSE 'Out of Stock'
    END AS availability_status,
    COALESCE(hav.avg_order_value, 0) AS avg_order_value,
    CASE 
        WHEN hvs.rank <= 5 THEN 'Top 5 Supplier'
        ELSE 'Other Supplier'
    END AS supplier_rank_status
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN 
    orders o ON li.l_orderkey = o.o_orderkey
LEFT JOIN 
    RankedSuppliers hvs ON ps.ps_suppkey = hvs.s_suppkey
LEFT JOIN 
    AvgCustomerOrderValue hav ON o.o_custkey = hav.c_custkey
WHERE 
    p.p_retailprice IS NOT NULL 
    AND p.p_size BETWEEN 1 AND 50
GROUP BY 
    p.p_name, hvs.rank, hav.avg_order_value
ORDER BY 
    total_available DESC,
    avg_order_value DESC
LIMIT 10;
