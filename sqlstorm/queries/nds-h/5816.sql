WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        DENSE_RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_availqty) DESC) AS brand_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_retailprice, p.p_comment
),
HighDemandParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.total_available_qty,
        rp.total_supply_cost
    FROM 
        RankedParts rp
    WHERE 
        rp.brand_rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    hp.p_name,
    hp.p_brand,
    hp.total_available_qty,
    hp.total_supply_cost,
    co.c_name,
    co.total_orders,
    co.total_spent
FROM 
    HighDemandParts hp
JOIN 
    lineitem l ON hp.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    CustomerOrders co ON o.o_custkey = co.c_custkey
WHERE 
    l.l_shipdate >= '1997-01-01'
    AND l.l_shipdate < '1998-01-01'
ORDER BY 
    hp.total_available_qty DESC, co.total_spent DESC
LIMIT 100;