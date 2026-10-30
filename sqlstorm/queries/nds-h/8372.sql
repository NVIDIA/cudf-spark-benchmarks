WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        SUM(ps.ps_availqty) AS total_avail_qty,
        DENSE_RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost) DESC) AS rank_by_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
),
HighSupplyParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_retailprice,
        rp.total_avail_qty
    FROM 
        RankedParts rp
    WHERE 
        rp.rank_by_supplycost <= 5
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    hvc.c_custkey,
    hvc.c_name,
    hvc.total_spent,
    hsp.p_partkey,
    hsp.p_name,
    hsp.p_brand,
    hsp.p_retailprice,
    hsp.total_avail_qty
FROM 
    HighValueCustomers hvc
JOIN 
    lineitem li ON hvc.c_custkey = li.l_orderkey
JOIN 
    HighSupplyParts hsp ON li.l_partkey = hsp.p_partkey
ORDER BY 
    hvc.total_spent DESC, hsp.p_retailprice ASC;
