
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn,
        p.p_partkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL AND 
        p.p_size BETWEEN 10 AND 20
),
QualifiedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(DISTINCT l.l_orderkey) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation,
        DENSE_RANK() OVER (PARTITION BY n.n_name ORDER BY c.c_acctbal DESC) AS rank_in_nation
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        c.c_acctbal IS NOT NULL
)
SELECT 
    cr.c_custkey,
    cr.c_name,
    cr.nation,
    COALESCE(SUM(ko.net_revenue), 0) AS total_revenue,
    CASE 
        WHEN SUM(ko.net_revenue) IS NULL THEN 'No Orders'
        WHEN cr.rank_in_nation = 1 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_status,
    (SELECT COUNT(*) FROM RankedSuppliers rs WHERE rs.rn = 1) AS top_suppliers_count
FROM 
    CustomerRegion cr
LEFT JOIN 
    QualifiedOrders ko ON cr.c_custkey = ko.o_orderkey
LEFT JOIN 
    RankedSuppliers r ON r.p_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#34' LIMIT 1)
GROUP BY 
    cr.c_custkey, cr.c_name, cr.nation, cr.rank_in_nation
HAVING 
    COALESCE(SUM(ko.net_revenue), 0) > (
        SELECT AVG(total_revenue) 
        FROM (
            SELECT SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue 
            FROM lineitem l 
            JOIN orders o ON l.l_orderkey = o.o_orderkey 
            WHERE o.o_orderstatus = 'O' 
            GROUP BY o.o_orderkey
        ) AS revenues
    )
ORDER BY 
    total_revenue DESC;
