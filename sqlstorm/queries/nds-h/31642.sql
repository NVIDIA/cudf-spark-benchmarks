WITH  Sales_Rank AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name, c.c_nationkey
),
Part_Supplier AS (
    SELECT
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM
        partsupp ps
    GROUP BY
        ps.ps_partkey
),
High_Cost_Parts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_brand,
        pc.total_cost
    FROM
        part p
    JOIN
        Part_Supplier pc ON p.p_partkey = pc.ps_partkey
    WHERE
        pc.total_cost > (
            SELECT AVG(total_cost) FROM Part_Supplier
        )
),
Customer_Sales AS (
    SELECT
        c.c_custkey,
        c.c_name,
        coalesce(SUM(o.o_totalprice), 0) AS total_spent,
        r.r_name AS region
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY
        c.c_custkey, c.c_name, r.r_name
)
SELECT
    cs.c_name,
    cs.region,
    cs.total_spent,
    s.rank AS customer_rank,
    h.p_name,
    h.p_brand,
    h.total_cost
FROM
    Customer_Sales cs
LEFT JOIN
    Sales_Rank s ON cs.c_custkey = s.c_custkey
INNER JOIN
    High_Cost_Parts h ON h.p_partkey IN (
        SELECT
            l.l_partkey
        FROM
            lineitem l
        INNER JOIN
            orders o ON l.l_orderkey = o.o_orderkey
        WHERE
            o.o_orderstatus = 'F'
            AND l.l_discount > 0.1
    )
WHERE
    (cs.total_spent > 1000 OR s.rank IS NULL)
ORDER BY
    cs.region, cs.total_spent DESC, s.rank;
