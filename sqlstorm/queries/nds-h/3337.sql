WITH RankedOrders AS (
    SELECT 
        o_orderkey,
        o_custkey,
        o_totalprice,
        o_orderdate,
        RANK() OVER (PARTITION BY o_custkey ORDER BY o_totalprice DESC) AS order_rank
    FROM 
        orders
    WHERE 
        o_orderdate >= DATE '1996-01-01'
), CustomerRevenue AS (
    SELECT 
        c.c_custkey,
        SUM(COALESCE(o.o_totalprice, 0)) AS total_revenue,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        RankedOrders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
), PartSupplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
), TopParts AS (
    SELECT 
        p.part_name,
        p.total_cost,
        RANK() OVER (ORDER BY p.total_cost DESC) AS rank
    FROM 
        (SELECT 
            name AS part_name,
            COALESCE(total_cost, 0) AS total_cost
         FROM 
            (SELECT 
                 p_name AS name,
                 SUM(ps_supplycost * ps_availqty) AS total_cost
             FROM 
                 part
             JOIN 
                 partsupp ON part.p_partkey = partsupp.ps_partkey
             GROUP BY 
                 p_name) AS subquery
        ) AS p
)
SELECT 
    c.c_name,
    cr.total_revenue,
    cr.order_count,
    tp.part_name,
    tp.total_cost
FROM 
    CustomerRevenue cr
INNER JOIN 
    customer c ON cr.c_custkey = c.c_custkey
LEFT JOIN 
    TopParts tp ON tp.rank <= 5
WHERE 
    cr.total_revenue > (SELECT AVG(total_revenue) FROM CustomerRevenue)
ORDER BY 
    cr.total_revenue DESC, tp.total_cost DESC