WITH  CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
RankedCustomers AS (
    SELECT 
        c.*, 
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY co.total_spent DESC) AS rank
    FROM 
        customer c
    JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
), 
PopularParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_quantity) AS total_sold
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
HighDemandParts AS (
    SELECT 
        pp.p_partkey, 
        pp.p_name, 
        pp.total_sold, 
        ps.ps_supplycost,
        (pp.total_sold * ps.ps_supplycost) AS total_revenue
    FROM 
        PopularParts pp
    JOIN 
        partsupp ps ON pp.p_partkey = ps.ps_partkey
    WHERE 
        ps.ps_availqty > (
            SELECT 
                AVG(ps_availqty) 
            FROM 
                partsupp 
            WHERE 
                ps_partkey = pp.p_partkey
        )
)
SELECT 
    nc.n_name AS nation,
    rc.c_name AS customer_name,
    hp.p_name AS popular_part,
    hp.total_sold,
    hp.total_revenue
FROM 
    nation nc
JOIN 
    rankedcustomers rc ON nc.n_nationkey = rc.c_nationkey
JOIN 
    HighDemandParts hp ON rc.rank <= 5
WHERE 
    rc.c_acctbal IS NOT NULL
ORDER BY 
    nc.n_name, hp.total_revenue DESC
LIMIT 10;
