WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_availqty) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type
),
HighSupplyParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.total_avail_qty,
        rp.total_supply_cost
    FROM 
        RankedParts rp
    WHERE 
        rp.rank <= 3
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    sop.p_partkey,
    sop.p_name,
    sop.p_brand,
    cos.c_custkey,
    cos.c_name,
    cos.order_count,
    cos.total_spent
FROM 
    HighSupplyParts sop
JOIN 
    CustomerOrderSummary cos ON sop.total_supply_cost < cos.total_spent
ORDER BY 
    sop.total_avail_qty DESC, 
    cos.total_spent DESC
LIMIT 10;
