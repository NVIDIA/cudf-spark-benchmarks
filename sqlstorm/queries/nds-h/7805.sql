
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= '1997-01-01'
    GROUP BY
        o.o_orderkey, o.o_orderdate
),
TopSellingProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity_sold,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        lineitem l
    JOIN
        part p ON l.l_partkey = p.p_partkey
    GROUP BY
        p.p_partkey, p.p_name
    ORDER BY
        total_revenue DESC
    LIMIT 10
),
CustomerRankings AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
)
SELECT 
    r.o_orderdate,
    r.total_sales,
    tp.p_name,
    tp.total_quantity_sold,
    cr.c_name,
    cr.total_spent
FROM
    RankedOrders r
JOIN
    TopSellingProducts tp ON tp.total_revenue > 1000
JOIN
    CustomerRankings cr ON cr.customer_rank <= 10
WHERE
    r.sales_rank = 1
ORDER BY
    r.total_sales DESC;
