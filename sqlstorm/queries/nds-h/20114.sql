WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
LatestOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) AS recent_order_rank
    FROM 
        orders o
),
FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_discount,
        CASE 
            WHEN l.l_discount > 0.2 THEN l.l_extendedprice * (1 - l.l_discount)
            ELSE l.l_extendedprice
        END AS adjusted_price
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
        AND l.l_returnflag IS NULL
),
OuterJoinedData AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(fli.adjusted_price), 0) AS total_spent,
        r.r_name
    FROM 
        customer c
    LEFT JOIN 
        LatestOrders lo ON c.c_custkey = lo.o_custkey
    LEFT JOIN 
        FilteredLineItems fli ON lo.o_orderkey = fli.l_orderkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        c.c_custkey, c.c_name, r.r_name
),
FinalResults AS (
    SELECT 
        o.r_name,
        COUNT(*) AS num_customers,
        AVG(o.total_spent) AS avg_spent,
        MAX(o.total_spent) AS max_spent,
        MIN(o.total_spent) AS min_spent,
        SUM(CASE WHEN o.total_spent IS NULL THEN 1 ELSE 0 END) AS null_count
    FROM 
        OuterJoinedData o
    GROUP BY 
        o.r_name
)
SELECT 
    r.r_name,
    CAST(f.avg_spent AS DECIMAL(12, 2)) AS average_spending,
    f.max_spent,
    f.min_spent,
    (SELECT COUNT(*) FROM RankedSuppliers rs WHERE rs.rank <= 3) AS top_suppliers_count
FROM 
    FinalResults f
JOIN 
    region r ON f.r_name = r.r_name
ORDER BY 
    f.avg_spent DESC NULLS LAST
LIMIT 10;