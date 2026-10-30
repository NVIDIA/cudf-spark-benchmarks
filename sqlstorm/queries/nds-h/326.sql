WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        p.p_size,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice < 500
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COALESCE(orders.order_count, 0) AS order_count,
        COALESCE(orders.total_spent, 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        CustomerOrders orders ON c.c_custkey = orders.c_custkey
    WHERE 
        c.c_acctbal > 1000 OR orders.total_spent > 10000
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    sa.total_availqty,
    fc.c_name,
    fc.order_count,
    RANK() OVER (PARTITION BY rp.p_brand ORDER BY sa.total_availqty DESC) AS rank_avail
FROM 
    RankedParts rp
LEFT JOIN 
    SupplierAvailability sa ON rp.p_partkey = sa.ps_partkey
JOIN 
    FilteredCustomers fc ON sa.total_availqty IS NOT NULL
WHERE 
    (rp.p_size > 10 AND fc.order_count > 5) OR fc.total_spent > 5000
ORDER BY 
    rp.p_brand, sa.total_availqty DESC;
