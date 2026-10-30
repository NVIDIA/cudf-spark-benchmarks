
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_by_price
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate >= '1996-01-01')
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 100.00
    GROUP BY 
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_name,
    COALESCE(sa.total_available, 0) AS total_avail_qty,
    COALESCE(co.total_orders, 0) AS total_orders,
    COALESCE(co.total_spent, 0) AS total_spent,
    ro.o_orderstatus,
    ro.o_totalprice,
    ro.o_orderdate
FROM 
    part p
LEFT JOIN 
    SupplierAvailability sa ON p.p_partkey = sa.ps_partkey
LEFT JOIN 
    CustomerOrders co ON EXISTS (
        SELECT 1 
        FROM lineitem l 
        WHERE l.l_partkey = p.p_partkey 
        AND l.l_orderkey IN (SELECT ro.o_orderkey FROM RankedOrders ro WHERE ro.rank_by_price <= 10)
    )
LEFT JOIN 
    RankedOrders ro ON ro.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey)
WHERE 
    p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice BETWEEN 20.00 AND 100.00)
    AND ro.o_orderdate IS NOT NULL
ORDER BY 
    p.p_name, ro.o_orderdate DESC;
