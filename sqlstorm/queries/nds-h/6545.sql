WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        SUM(ps.ps_availqty) AS total_available_quantity,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_availqty) DESC) AS rnk
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
),
TopParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_retailprice,
        rp.total_available_quantity,
        rp.supplier_count
    FROM 
        RankedParts rp
    WHERE 
        rp.rnk <= 5
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    tos.p_partkey,
    tos.p_name,
    tos.p_brand,
    tos.p_retailprice,
    tos.total_available_quantity,
    tos.supplier_count,
    cos.c_custkey,
    cos.c_name,
    cos.total_spent,
    cos.total_orders
FROM 
    TopParts tos
JOIN 
    CustomerOrderSummary cos ON cos.total_spent > 1000
ORDER BY 
    tos.total_available_quantity DESC, cos.total_spent DESC
LIMIT 10;
