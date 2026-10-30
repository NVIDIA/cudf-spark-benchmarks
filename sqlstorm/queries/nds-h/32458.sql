
WITH  RegionalSales AS (
    SELECT
        r.r_regionkey,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM
        region r
    JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY
        r.r_regionkey, r.r_name
    UNION ALL
    SELECT
        r.r_regionkey,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM
        region r
    JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY
        r.r_regionkey, r.r_name
    HAVING
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
CustomerBalances AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(o.o_totalprice), 0) AS total_spend,
        CASE 
            WHEN c.c_acctbal < 0 THEN 'Overdrawn'
            ELSE 'Good Standing'
        END AS account_status
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name, c.c_acctbal
),
RankedSales AS (
    SELECT
        r.r_name,
        rs.total_sales,
        RANK() OVER (PARTITION BY r.r_name ORDER BY rs.total_sales DESC) AS sales_rank
    FROM
        RegionalSales rs
    JOIN
        region r ON rs.r_regionkey = r.r_regionkey
)
SELECT
    rb.c_name,
    rb.total_spend,
    rb.account_status,
    rs.r_name,
    rs.total_sales,
    rs.sales_rank
FROM
    CustomerBalances rb
LEFT JOIN 
    RankedSales rs ON rb.total_spend > 10000
WHERE
    rb.account_status = 'Good Standing'
ORDER BY
    rs.sales_rank, rb.total_spend DESC
LIMIT 100;
