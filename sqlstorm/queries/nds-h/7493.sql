
WITH RegionStats AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
),
TopSuppliers AS (
    SELECT 
        s.s_name AS supplier_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty > 0
    GROUP BY 
        s.s_name
    ORDER BY 
        total_supply_value DESC
    LIMIT 10
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS part_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey
),
FinalReport AS (
    SELECT 
        rs.region_name,
        rs.nation_count,
        rs.total_supplier_balance,
        ts.supplier_name,
        ts.total_supply_value,
        os.total_revenue,
        os.part_count
    FROM 
        RegionStats rs
    LEFT JOIN 
        TopSuppliers ts ON rs.region_name = (
            SELECT r.r_name 
            FROM region r 
            JOIN nation n ON r.r_regionkey = n.n_regionkey 
            WHERE n.n_nationkey = (
                SELECT s.s_nationkey 
                FROM supplier s 
                ORDER BY s.s_acctbal DESC 
                LIMIT 1
            )
            LIMIT 1
        )
    LEFT JOIN 
        OrderStats os ON os.o_orderkey = (
            SELECT o.o_orderkey 
            FROM orders o 
            ORDER BY o.o_totalprice DESC 
            LIMIT 1
        )
)
SELECT 
    region_name,
    nation_count,
    total_supplier_balance,
    supplier_name,
    total_supply_value,
    total_revenue,
    part_count
FROM 
    FinalReport
ORDER BY 
    total_supplier_balance DESC, 
    total_revenue DESC;
