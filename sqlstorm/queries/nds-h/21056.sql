WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY ns.n_regionkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation ns ON s.s_nationkey = ns.n_nationkey
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS total_items,
        AVG(l.l_quantity) AS avg_quantity_per_item
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
        AND o.o_orderdate >= '1995-01-01' 
    GROUP BY 
        o.o_orderkey
), 
MaxRevenue AS (
    SELECT 
        MAX(total_revenue) AS max_revenue
    FROM 
        OrderDetails
    WHERE 
        total_items > (SELECT AVG(total_items) FROM OrderDetails)
)
SELECT 
    ps.ps_partkey, 
    p.p_name, 
    p.p_brand, 
    p.p_type, 
    SUM(ps.ps_availqty) AS total_available_quantity,
    COALESCE(MAX(s.s_name), 'No Supplier') AS max_supplier_name,
    COALESCE(ROUND(AVG(l.l_extendedprice * (1 - l.l_discount)), 2), 0.00) AS avg_price,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) = 0 THEN 'No Orders' 
        WHEN COUNT(DISTINCT o.o_orderkey) > 3 THEN 'Multiple Orders' 
        ELSE 'Single Order' 
    END AS order_count_description
FROM 
    partsupp ps
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey AND s.rnk = 1
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
WHERE 
    ps.ps_supplycost < (SELECT MAX(ps_supplycost) FROM partsupp WHERE ps_availqty > 0)
    AND p.p_size BETWEEN 10 AND 20 
    AND p.p_comment NOT LIKE '%fragile%'
GROUP BY 
    ps.ps_partkey, p.p_name, p.p_brand, p.p_type
HAVING 
    COUNT(DISTINCT o.o_orderkey) FILTER (WHERE o.o_orderstatus = 'O') > 0
    AND SUM(l.l_extendedprice) < (SELECT max_revenue FROM MaxRevenue)
ORDER BY 
    total_available_quantity DESC, 
    avg_price DESC
LIMIT 100 OFFSET 10;
