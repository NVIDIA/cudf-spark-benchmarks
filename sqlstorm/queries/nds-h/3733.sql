
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate <= '1997-12-31'
),
CustomerStats AS (
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
PartSupplement AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
),
PopularProducts AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        l.l_partkey
    ORDER BY 
        total_quantity DESC
    LIMIT 10
)
SELECT 
    cs.c_custkey,
    cs.order_count,
    cs.total_spent,
    pp.l_partkey,
    pp.total_quantity,
    ps.total_cost,
    COALESCE(SUM(CASE WHEN ro.rank = 1 THEN ro.o_totalprice END), 0) AS highest_order_value
FROM 
    CustomerStats cs
LEFT JOIN 
    PopularProducts pp ON pp.l_partkey IN (SELECT ps.p_partkey FROM PartSupplement ps WHERE ps.total_cost < 10000)
LEFT JOIN 
    RankedOrders ro ON cs.c_custkey = ro.o_custkey
LEFT JOIN 
    PartSupplement ps ON pp.l_partkey = ps.p_partkey
WHERE 
    cs.order_count > 5
GROUP BY 
    cs.c_custkey, cs.order_count, cs.total_spent, pp.l_partkey, pp.total_quantity, ps.total_cost
ORDER BY 
    cs.total_spent DESC, pp.total_quantity DESC;
