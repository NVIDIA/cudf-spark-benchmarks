WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type
),
TopParts AS (
    SELECT 
        p_type,
        p_name,
        total_supply_cost
    FROM 
        RankedParts
    WHERE 
        rnk <= 10
),
CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_purchases
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PurchaseStats AS (
    SELECT 
        tp.p_type,
        AVG(cp.total_purchases) AS avg_purchase,
        COUNT(cp.c_custkey) AS customer_count
    FROM 
        TopParts tp
    JOIN 
        CustomerPurchases cp ON tp.p_name = cp.c_name
    GROUP BY 
        tp.p_type
)
SELECT 
    ps.p_type,
    ps.avg_purchase,
    ps.customer_count,
    r.r_name
FROM 
    PurchaseStats ps
JOIN 
    nation n ON ps.customer_count > 10
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE 'Asia%'
ORDER BY 
    ps.avg_purchase DESC;
