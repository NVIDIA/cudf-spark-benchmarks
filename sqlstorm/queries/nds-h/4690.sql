WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2 
            WHERE s2.s_nationkey = s.s_nationkey
        )
),
HighAccountCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
MinMaxPrices AS (
    SELECT 
        p.p_partkey,
        MIN(p.p_retailprice) AS min_price,
        MAX(p.p_retailprice) AS max_price
    FROM 
        part p
    GROUP BY 
        p.p_partkey
)
SELECT 
    ns.n_name,
    hs.c_name,
    hs.total_spent,
    rs.s_name AS supplier_name,
    rs.s_acctbal,
    mmp.min_price,
    mmp.max_price
FROM 
    nation ns
LEFT JOIN 
    HighAccountCustomers hs ON ns.n_nationkey = hs.c_custkey
LEFT JOIN 
    RankedSuppliers rs ON ns.n_nationkey = rs.s_suppkey
JOIN 
    MinMaxPrices mmp ON rs.s_suppkey = mmp.p_partkey
WHERE 
    rs.rn = 1 AND 
    (mmp.min_price IS NOT NULL OR mmp.max_price IS NOT NULL)
ORDER BY 
    ns.n_name, hs.total_spent DESC, rs.s_acctbal DESC;