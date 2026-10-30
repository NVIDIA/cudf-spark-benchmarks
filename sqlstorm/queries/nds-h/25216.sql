WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS BrandRank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COALESCE(co.TotalOrders, 0) AS TotalOrders,
        COALESCE(co.TotalSpent, 0.00) AS TotalSpent
    FROM 
        customer c
    LEFT JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    tp.c_custkey,
    tp.c_name,
    tp.TotalOrders,
    tp.TotalSpent,
    CASE 
        WHEN tp.TotalSpent > 10000 THEN 'High Value'
        WHEN tp.TotalSpent BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS CustomerValueCategory
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    TopCustomers tp ON n.n_nationkey = tp.c_custkey
WHERE 
    rp.BrandRank <= 5 
ORDER BY 
    rp.p_retailprice DESC, 
    tp.TotalSpent DESC;
