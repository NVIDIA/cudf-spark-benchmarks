WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
TopRankedParts AS (
    SELECT 
        rp.p_partkey, 
        rp.p_name, 
        rp.total_supplycost
    FROM 
        RankedParts rp
    WHERE 
        rp.rank <= 10
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey, 
        c.c_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_custkey
),
TopCustomers AS (
    SELECT 
        co.c_custkey, 
        SUM(co.revenue) AS total_revenue
    FROM 
        CustomerOrders co
    GROUP BY 
        co.c_custkey
    ORDER BY 
        total_revenue DESC
    LIMIT 5
)
SELECT 
    tc.c_custkey, 
    SUM(trp.total_supplycost) AS avg_supply_cost_per_customer
FROM 
    TopCustomers tc
JOIN 
    TopRankedParts trp ON trp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps)
GROUP BY 
    tc.c_custkey
ORDER BY 
    avg_supply_cost_per_customer DESC;
