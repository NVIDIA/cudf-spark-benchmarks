WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL AND 
        p.p_size BETWEEN 1 AND 100
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal, 
        (CASE WHEN s.s_acctbal IS NULL THEN 0 ELSE s.s_acctbal END) AS adjusted_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal < (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_acctbal IS NOT NULL)
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_totalprice,
        COUNT(l.l_orderkey) AS line_count,
        SUM(l.l_extendedprice) AS total_extended_price,
        MAX(l.l_discount) AS max_discount,
        MIN(l.l_tax) AS min_tax
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' AND 
        l.l_shipdate IS NOT NULL
    GROUP BY 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_totalprice
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1997-12-31'
    GROUP BY 
        c.c_custkey, 
        c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
)
SELECT 
    cu.c_name,
    cu.total_spent,
    sp.s_name AS supplier_name,
    rp.p_name AS top_part,
    rp.p_retailprice AS top_part_price,
    CASE 
        WHEN cu.total_spent > 20000 THEN 'VIP' 
        ELSE 'Regular' 
    END AS customer_status
FROM 
    HighValueCustomers cu
LEFT JOIN 
    SupplierDetails sp ON cu.c_custkey = sp.s_nationkey
LEFT JOIN 
    RankedParts rp ON rp.brand_rank = 1
WHERE 
    (cu.total_spent > 15000 OR sp.adjusted_acctbal > 500)
    AND rp.p_size IS NOT NULL
ORDER BY 
    cu.total_spent DESC, 
    rp.p_retailprice ASC;