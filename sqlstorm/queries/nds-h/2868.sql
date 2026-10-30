
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_available,
        ss.avg_supply_cost,
        RANK() OVER (ORDER BY ss.total_available DESC) AS rank
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
),
OrderSummary AS (
    SELECT  
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount,
        COUNT(DISTINCT o.o_custkey) AS customer_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    ts.s_name,
    ts.total_available,
    os.total_amount,
    os.customer_count,
    CASE 
        WHEN ts.avg_supply_cost IS NULL THEN 'No Data'
        WHEN ts.avg_supply_cost > 100 THEN 'High Cost'
        ELSE 'Normal Cost'
    END AS cost_category
FROM 
    TopSuppliers ts
LEFT JOIN 
    OrderSummary os ON ts.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_type LIKE '%BRASS%') LIMIT 1)
WHERE 
    ts.rank <= 10
ORDER BY 
    ts.total_available DESC, os.total_amount DESC;
