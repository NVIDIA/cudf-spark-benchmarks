WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        MAX(ps.ps_supplycost) AS max_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS customer_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    sd.s_name,
    sd.nation_name,
    sd.region_name,
    COUNT(DISTINCT os.o_orderkey) AS total_orders,
    SUM(os.total_revenue) AS total_revenue,
    AVG(sd.s_acctbal) AS average_supplier_balance
FROM 
    SupplierDetails sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    PartSupplier p ON ps.ps_partkey = p.ps_partkey
JOIN 
    OrderSummary os ON ps.ps_partkey = os.o_orderkey
WHERE 
    p.max_supplycost > 100.00
GROUP BY 
    sd.s_name, sd.nation_name, sd.region_name
ORDER BY 
    total_revenue DESC, total_orders DESC;