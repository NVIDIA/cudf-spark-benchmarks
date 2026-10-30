
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
        AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
NationSupplier AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
),
CombinedData AS (
    SELECT 
        ns.n_name,
        ss.s_name,
        ss.total_available,
        ss.total_value,
        os.total_revenue,
        os.line_item_count,
        ROW_NUMBER() OVER (PARTITION BY ns.n_name ORDER BY ss.total_value DESC) AS rank
    FROM 
        SupplierStats ss
    JOIN 
        lineitem l ON ss.s_suppkey = l.l_suppkey
    JOIN 
        OrderSummary os ON l.l_orderkey = os.o_orderkey
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    JOIN 
        nation ns ON s.s_nationkey = ns.n_nationkey
)
SELECT 
    ns.n_name,
    cd.s_name,
    cd.total_available,
    cd.total_value,
    cd.total_revenue,
    cd.line_item_count
FROM 
    NationSupplier ns
JOIN 
    CombinedData cd ON ns.n_name = cd.n_name
WHERE 
    cd.rank <= 3
ORDER BY 
    ns.n_name,
    cd.total_value DESC;
