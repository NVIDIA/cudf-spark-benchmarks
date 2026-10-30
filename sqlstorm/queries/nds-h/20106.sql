WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_shippriority,
        COUNT(li.l_orderkey) AS line_item_count
    FROM 
        orders o
    LEFT JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_shippriority
),
NullCheck AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COALESCE(NULLIF(s.s_name, ''), 'UNKNOWN') AS supplier_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        orders o ON s.s_suppkey = o.o_custkey
    GROUP BY 
        n.n_nationkey, n.n_name, s.s_name
),
FinalResults AS (
    SELECT 
        r.r_name,
        SUM(CASE WHEN ns.order_count > 0 THEN 1 ELSE 0 END) AS active_suppliers,
        AVG(CASE WHEN hs.line_item_count > 0 THEN hs.o_totalprice ELSE NULL END) AS avg_high_value_order_price
    FROM 
        region r
    LEFT JOIN 
        NullCheck ns ON r.r_regionkey = ns.n_nationkey
    LEFT JOIN 
        HighValueOrders hs ON ns.order_count = ns.order_count
    GROUP BY 
        r.r_name
    HAVING 
        COUNT(DISTINCT r.r_regionkey) > 1
)
SELECT 
    fr.r_name,
    fr.active_suppliers,
    fr.avg_high_value_order_price,
    CASE WHEN fr.avg_high_value_order_price IS NULL THEN 'No Orders' ELSE 'Has Orders' END AS order_status
FROM 
    FinalResults fr
WHERE 
    fr.active_suppliers > 2
ORDER BY 
    fr.avg_high_value_order_price DESC NULLS LAST
LIMIT 10 OFFSET 5;
