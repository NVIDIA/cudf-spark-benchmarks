WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        p.p_retailprice, 
        ps.ps_availqty, 
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
),
FilteredParts AS (
    SELECT 
        rp.p_partkey, 
        rp.p_name, 
        rp.p_brand, 
        rp.p_type, 
        rp.p_retailprice, 
        rp.ps_availqty
    FROM 
        RankedParts rp
    WHERE 
        rp.rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
)
SELECT 
    f.p_brand, 
    COUNT(DISTINCT co.o_orderkey) AS order_count, 
    SUM(co.o_totalprice) AS total_revenue, 
    MAX(co.o_orderdate) AS last_order_date
FROM 
    FilteredParts f
JOIN 
    lineitem l ON f.p_partkey = l.l_partkey
JOIN 
    CustomerOrders co ON l.l_orderkey = co.o_orderkey
GROUP BY 
    f.p_brand
ORDER BY 
    total_revenue DESC;
