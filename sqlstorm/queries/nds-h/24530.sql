WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS RankByAccountBalance
    FROM 
        supplier s
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_retailprice > 500 THEN 'High'
            WHEN p.p_retailprice BETWEEN 300 AND 500 THEN 'Medium'
            ELSE 'Low'
        END AS PriceCategory
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        COUNT(DISTINCT l.l_linenumber) AS LineCount
    FROM 
        lineitem l
    WHERE 
        l.l_discount IS NOT NULL
    GROUP BY 
        l.l_orderkey
),
CustomerNation AS (
    SELECT 
        c.c_custkey,
        n.n_name,
        COUNT(o.o_orderkey) AS OrderCount
    FROM 
        customer c
    LEFT JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, n.n_name
)
SELECT 
    rs.s_suppkey,
    rs.s_name,
    hp.p_name,
    hp.PriceCategory,
    l.TotalRevenue,
    cn.n_name,
    cn.OrderCount
FROM 
    RankedSuppliers rs
JOIN 
    partsupp ps ON rs.s_suppkey = ps.ps_suppkey
JOIN 
    HighValueParts hp ON ps.ps_partkey = hp.p_partkey
LEFT JOIN 
    LineItemStats l ON l.l_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name = 'CustomerX' LIMIT 1) LIMIT 1)
LEFT JOIN 
    CustomerNation cn ON cn.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name = 'CustomerX' LIMIT 1)
WHERE 
    rs.RankByAccountBalance <= 5
    AND (hp.p_retailprice IS NOT NULL OR hp.p_retailprice IS NULL)
ORDER BY 
    l.TotalRevenue DESC NULLS LAST;
