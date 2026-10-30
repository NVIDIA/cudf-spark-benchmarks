WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        rs.s_name AS supplier_name,
        rs.total_available_quantity
    FROM RankedSuppliers rs
    JOIN nation n ON rs.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE rs.rank <= 5
)
SELECT 
    ts.region_name,
    ts.nation_name,
    ts.supplier_name,
    ts.total_available_quantity,
    CONCAT('Supplier ', ts.supplier_name, ' from ', ts.nation_name, ' in ', ts.region_name, ' has ', ts.total_available_quantity, ' items available.') AS supplier_details
FROM TopSuppliers ts
ORDER BY ts.region_name, ts.nation_name, ts.total_available_quantity DESC;
