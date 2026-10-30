
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_price
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 10 AND 
        (p.p_comment IS NULL OR p.p_comment LIKE '%excellent%')
), 
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    JOIN 
        RankedParts rp ON ps.ps_partkey = rp.p_partkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        c.c_nationkey
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        c.c_custkey, c.c_nationkey
), 
NationHighestSpend AS (
    SELECT 
        n.n_name,
        SUM(co.total_spent) AS national_spend,
        COUNT(DISTINCT co.c_custkey) AS active_customers
    FROM 
        nation n
    JOIN 
        CustomerOrders co ON n.n_nationkey = co.c_nationkey
    GROUP BY 
        n.n_name
    HAVING 
        SUM(co.total_spent) > (SELECT AVG(total_spent) FROM CustomerOrders)
)
SELECT 
    n.n_name,
    nh.active_customers,
    COALESCE(ROUND(SUM(sp.total_available), 2), 0) AS total_part_avail
FROM 
    NationHighestSpend nh
LEFT JOIN 
    SupplierAvailability sp ON nh.active_customers > 5
RIGHT JOIN 
    nation n ON nh.n_name = n.n_name
WHERE 
    n.n_name IS NOT NULL 
GROUP BY 
    n.n_name, nh.active_customers
ORDER BY 
    total_part_avail DESC, 
    nh.active_customers ASC
LIMIT 10;
