
WITH RegionalSales AS (
    SELECT
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM
        nation n
        JOIN region r ON n.n_regionkey = r.r_regionkey
        JOIN supplier s ON n.n_nationkey = s.s_nationkey
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        JOIN part p ON ps.ps_partkey = p.p_partkey
        JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY
        n.n_name, r.r_name
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        SUM(o.o_totalprice) AS customer_spending
    FROM
        customer c
        JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey
),
TopCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COALESCE(co.customer_spending, 0) AS total_spending
    FROM
        customer c
        LEFT JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
    ORDER BY
        total_spending DESC
    LIMIT 10
)
SELECT
    r.nation_name,
    r.region_name,
    r.total_sales,
    tc.c_custkey,
    tc.c_name,
    tc.total_spending
FROM
    RegionalSales r
    LEFT JOIN TopCustomers tc ON r.nation_name = (
        SELECT n.n_name 
        FROM nation n 
        JOIN supplier s ON n.n_nationkey = s.s_nationkey 
        WHERE s.s_suppkey = (
            SELECT ps.ps_suppkey 
            FROM partsupp ps 
            JOIN part p ON ps.ps_partkey = p.p_partkey 
            WHERE p.p_name LIKE '%metal%'
            LIMIT 1
        )
    )
WHERE
    r.total_sales > (
        SELECT AVG(total_sales)
        FROM RegionalSales
    )
ORDER BY 
    r.total_sales DESC, 
    tc.total_spending DESC;
