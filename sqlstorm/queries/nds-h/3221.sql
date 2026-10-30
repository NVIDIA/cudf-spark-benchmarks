WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighRevenueParts AS (
    SELECT 
        r.p_partkey,
        r.total_revenue
    FROM 
        RankedSales r
    WHERE 
        r.rank = 1
)

SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    ss.total_parts_supplied,
    ss.total_supply_value,
    hr.total_revenue,
    CASE 
        WHEN s.s_acctbal IS NULL THEN 'No Account Balance'
        ELSE CAST(s.s_acctbal AS STRING) 
    END AS account_balance
FROM 
    part p 
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
JOIN 
    HighRevenueParts hr ON p.p_partkey = hr.p_partkey
WHERE 
    (p.p_size > 20 OR p.p_retailprice < 100) 
ORDER BY 
    hr.total_revenue DESC
LIMIT 50;
