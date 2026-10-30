WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM
        supplier s
),
FilteredParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_size,
        CASE 
            WHEN p.p_size IS NULL THEN 'UNKNOWN'
            WHEN p.p_size < 10 THEN 'SMALL'
            WHEN p.p_size BETWEEN 10 AND 20 THEN 'MEDIUM'
            ELSE 'LARGE'
        END AS size_category
    FROM
        part p
    WHERE
        p.p_retailprice IS NOT NULL AND p.p_retailprice > 1000
),
SupplierParts AS (
    SELECT
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        pp.p_name,
        pp.size_category
    FROM
        partsupp ps
    JOIN
        FilteredParts pp ON ps.ps_partkey = pp.p_partkey
),
OrderSummary AS (
    SELECT
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_custkey
),
CustomerPerformance AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COALESCE(o.total_revenue, 0) AS total_revenue,
        o.order_count,
        CASE 
            WHEN o.total_revenue IS NULL THEN 'NO ORDERS'
            WHEN o.total_revenue < 5000 THEN 'LOW SPENDER'
            WHEN o.total_revenue BETWEEN 5000 AND 20000 THEN 'AVERAGE SPENDER'
            ELSE 'HIGH ROLLER'
        END AS spending_category
    FROM
        customer c
    LEFT JOIN
        OrderSummary o ON c.c_custkey = o.o_custkey
),
TopSuppliers AS (
    SELECT
        rs.s_name,
        COUNT(sp.ps_partkey) AS parts_supplied,
        AVG(sp.ps_supplycost) AS avg_supply_cost
    FROM
        RankedSuppliers rs
    JOIN
        SupplierParts sp ON rs.s_suppkey = sp.ps_suppkey
    WHERE
        rs.rnk = 1
    GROUP BY
        rs.s_name
)
SELECT
    cp.c_name,
    cp.total_revenue,
    cp.spending_category,
    ts.parts_supplied,
    ts.avg_supply_cost
FROM
    CustomerPerformance cp
LEFT JOIN 
    TopSuppliers ts ON cp.total_revenue > 10000
WHERE 
    cp.spending_category <> 'NO ORDERS'
ORDER BY 
    cp.total_revenue DESC
LIMIT 10;
