WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS SupplierRank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(subQuery.total_order_amount) AS TotalOrders
    FROM 
        nation n
    LEFT JOIN (
        SELECT 
            c.c_nationkey,
            SUM(o.o_totalprice) AS total_order_amount
        FROM 
            customer c
        JOIN 
            orders o ON c.c_custkey = o.o_custkey
        GROUP BY 
            c.c_nationkey
    ) subQuery ON n.n_nationkey = subQuery.c_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        SUM(subQuery.total_order_amount) IS NOT NULL
)
SELECT 
    p.p_name,
    p.p_size,
    CASE 
        WHEN ps.ps_availqty IS NULL THEN 'No Supply Available'
        ELSE CONCAT('Available: ', ps.ps_availqty)
    END AS Availability,
    COALESCE(rs.s_name, 'Unknown Supplier') AS SupplierName,
    tn.TotalOrders,
    RANK() OVER (ORDER BY p.p_retailprice DESC) AS PriceRank
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey AND rs.SupplierRank <= 5
JOIN 
    TopNations tn ON tn.n_nationkey = (
        SELECT n.n_nationkey 
        FROM nation n 
        WHERE n.n_name LIKE 'A%'
        ORDER BY n.n_name DESC 
        LIMIT 1
    )
WHERE 
    (p.p_retailprice > 100 OR
    (ps.ps_supplycost IS NOT NULL AND ps.ps_supplycost < 50) OR
    (p.p_type = 'fragile' AND p.p_size > 20))
ORDER BY 
    p.p_retailprice ASC,
    Availability DESC
LIMIT 20 OFFSET 10;
